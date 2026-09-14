import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/access_model.dart';
import '../models/support_model.dart';

/// An event's support requests in Firestore —
/// `events/{eventId}/supportRequests/{requestId}`, with
/// `messages/{messageId}` beneath each request.
///
/// This is a collection the app *writes*: a participant opens a request and adds
/// messages to it; the admin panel replies and resolves. Unlike the feed and the
/// gallery, a request is private to its author and the event's managers, so
/// every query here filters on `requesterId` — not as a convenience, but because
/// the security rules refuse a list query that doesn't (a rule can't filter a
/// collection, it can only reject a query that could return documents the caller
/// may not read).
class SupportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _requests(String eventId) =>
      _firestore
          .collection(Collections.events)
          .doc(eventId)
          .collection(Collections.supportRequests);

  DocumentReference<Map<String, dynamic>> _request(
    String eventId,
    String requestId,
  ) => _requests(eventId).doc(requestId);

  CollectionReference<Map<String, dynamic>> _messages(
    String eventId,
    String requestId,
  ) => _request(eventId, requestId).collection(Collections.supportMessages);

  // --- Requests ------------------------------------------------------------

  /// The signed-in user's own requests, most recently active first, as a live
  /// stream.
  ///
  /// Ordered by `lastMessageAt` rather than `createdAt`: what the user is
  /// looking for is the conversation that just moved, not the one they happened
  /// to open first. A request whose first message hasn't had its server
  /// timestamp resolved yet sorts last on some clients, which is why the list
  /// screen re-sorts what arrives.
  Stream<List<SupportRequest>> watchMyRequests(String eventId, String uid) {
    return _requests(eventId)
        .where('requesterId', isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              // The document id wins over any stale `id` in the body.
              .map(
                (doc) => SupportRequest.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// One request, live — what the chat screen's header reads.
  ///
  /// Resolves to null when the document isn't there, which is what a request the
  /// panel has deleted looks like from here: the screen says so rather than
  /// sitting on a stale copy. Streaming it is also how the participant sees a
  /// thread being marked resolved while they have it open.
  Stream<SupportRequest?> watchRequest(String eventId, String requestId) {
    return _request(eventId, requestId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return SupportRequest.fromJson({...data, 'id': doc.id});
    });
  }

  /// Open a request with its first message, and return its new id.
  ///
  /// The request document and its first message go in ONE batch. If they could
  /// land separately, a failure between them would leave a request with an empty
  /// thread — a row in the participant's list, and in the admin's queue, with
  /// nothing in it to answer.
  ///
  /// The denormalized snapshot is derived by
  /// [SupportRequest.patchForMessage], the same call the app and the panel use
  /// for every later message, so a brand-new request is in exactly the state one
  /// message would have put it in. `createdAt` is stamped here; the patch
  /// supplies `updatedAt`, `lastMessage*` and the `messageCount` increment.
  Future<String> openRequest({
    required String eventId,
    required String requesterId,
    required String requesterName,
    String? requesterImage,
    required String subject,
    required String message,
  }) async {
    final requestRef = _requests(eventId).doc();
    final messageRef = _messages(eventId, requestRef.id).doc();
    final batch = _firestore.batch();

    batch.set(requestRef, {
      ...SupportRequest.openFields(
        requesterId: requesterId,
        requesterName: requesterName,
        requesterImage: requesterImage,
        subject: subject,
      ),
      ...SupportRequest.patchForMessage(
        senderRole: SupportSenderRole.user,
        message: message,
        currentStatus: SupportRequestStatus.open,
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(messageRef, {
      ...SupportMessage(
        id: messageRef.id,
        requestId: requestRef.id,
        eventId: eventId,
        senderRole: SupportSenderRole.user,
        senderId: requesterId,
        senderName: requesterName,
        message: message,
        createdAt: null,
      ).toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return requestRef.id;
  }

  // --- Messages ------------------------------------------------------------

  /// A request's messages, oldest first — the order a conversation reads in.
  Stream<List<SupportMessage>> watchMessages(String eventId, String requestId) {
    return _messages(eventId, requestId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => SupportMessage.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// Add the participant's message to a thread and return its new id.
  ///
  /// Batched with the parent's snapshot for the same reason a reply is in the
  /// panel: a thread whose list row disagrees with its contents — showing as
  /// answered while carrying an unanswered question — is precisely the state the
  /// admin queue is meant to be trusted for.
  ///
  /// [currentStatus] is what the thread was in when the composer was drawn; a
  /// message sent into a resolved thread reopens it.
  Future<String> sendMessage({
    required String eventId,
    required String requestId,
    required String senderId,
    required String senderName,
    required String message,
    required SupportRequestStatus currentStatus,
  }) async {
    final messageRef = _messages(eventId, requestId).doc();
    final batch = _firestore.batch();

    batch.set(messageRef, {
      ...SupportMessage(
        id: messageRef.id,
        requestId: requestId,
        eventId: eventId,
        senderRole: SupportSenderRole.user,
        senderId: senderId,
        senderName: senderName,
        message: message,
        createdAt: null,
      ).toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(
      _request(eventId, requestId),
      SupportRequest.patchForMessage(
        senderRole: SupportSenderRole.user,
        message: message,
        currentStatus: currentStatus,
      ),
    );

    await batch.commit();
    return messageRef.id;
  }
}
