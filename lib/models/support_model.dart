import 'package:cloud_firestore/cloud_firestore.dart';

/// Support requests — a private conversation between one participant and the
/// event's managers.
///
/// A participant opens a request from the app with a short subject and a first
/// message; the event's admins answer it from the admin panel's "Support
/// Requests" section. The thread runs until an admin marks it resolved.
///
/// Firestore layout — a subcollection of the event, like every other feature:
///
///   events/{eventId}/supportRequests/{requestId}
///   events/{eventId}/supportRequests/{requestId}/messages/{messageId}
///
/// Messages are a subcollection, NOT an array on the request: a conversation
/// grows without bound, so an array would push the request document toward the
/// 1 MB limit, and a whole-array write is last-writer-wins — two people replying
/// at the same moment would clobber each other. This is the same call the
/// community feed makes for its comments.
///
/// The cost is that a list of requests can't show a preview, or sort by who
/// spoke last, without reading every thread. So the request carries a
/// denormalized snapshot of its most recent message ([lastMessageText],
/// [lastMessageAt], [lastMessageSenderRole]) plus a [messageCount].
/// [SupportRequest.patchForMessage] is the single place those are derived.
///
/// Unlike the community feed, these are NOT visible to everyone who can see the
/// event: a request is readable by its author and by the event's managers, and
/// by nobody else. The security rules enforce that, which is why every list
/// query here filters on `requesterId`.
///
/// Nothing here is localised: a support conversation happens in whatever single
/// language the two people share, so [subject] and [message] are plain strings —
/// these documents carry no `isMultilingual` flag.
///
/// Kept in sync with the admin panel's `types/support.ts` — the app writes what
/// the panel reads, so the two shapes must agree.

/// Which side of the conversation a message came from.
///
/// Deliberately a role rather than a uid comparison: the panel has to classify a
/// message without knowing which admin (of possibly several) is reading it.
enum SupportSenderRole {
  user('user'),
  admin('admin');

  const SupportSenderRole(this.jsonValue);

  final String jsonValue;

  /// Parse the stored value, defaulting to [user] for anything unrecognised.
  static SupportSenderRole fromJson(String? value) =>
      value == 'admin' ? SupportSenderRole.admin : SupportSenderRole.user;
}

/// Where the request stands, as set by an admin.
///
/// [open] is every request that still needs looking after; [resolved] is one an
/// admin has closed out. A participant replying to a resolved thread reopens it
/// (see [SupportRequest.patchForMessage]).
enum SupportRequestStatus {
  open('open'),
  resolved('resolved');

  const SupportRequestStatus(this.jsonValue);

  final String jsonValue;

  static SupportRequestStatus fromJson(String? value) =>
      value == 'resolved'
      ? SupportRequestStatus.resolved
      : SupportRequestStatus.open;
}

/// One support conversation.
///
/// [requesterName] and [requesterImage] are a snapshot taken when the request is
/// opened. A company admin cannot read other users' `users/{uid}` documents, so
/// without them the panel's queue would have no name to draw. A later name
/// change doesn't rewrite old requests — the same trade-off the community feed
/// accepts for its posts.
class SupportRequest {
  final String id;

  /// The uid of the participant who opened the request.
  final String requesterId;
  final String requesterName;
  final String? requesterImage;

  /// A short, plain-text summary the participant types when opening the request.
  final String subject;

  final SupportRequestStatus status;

  /// True when the last message came from the participant — i.e. the thread is
  /// waiting on an admin.
  ///
  /// Stored rather than derived so the panel's queue is one indexed query
  /// instead of a read per thread. From the app's side it is what marks a thread
  /// as answered: `!awaitingReply` means the support team has spoken last.
  final bool awaitingReply;

  /// A truncated copy of the most recent message, for a list row.
  final String lastMessageText;

  /// When the most recent message was sent. Both lists sort on this.
  final DateTime? lastMessageAt;

  final SupportSenderRole lastMessageSenderRole;

  /// Total messages in the thread, kept in step by an `increment()` on send.
  final int messageCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// When an admin last marked the request resolved; null while it is open.
  final DateTime? resolvedAt;

  /// The uid of the admin who resolved it; null while it is open.
  final String? resolvedBy;

  const SupportRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterImage,
    required this.subject,
    required this.status,
    required this.awaitingReply,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.lastMessageSenderRole,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  /// Whether the thread is still waiting on the support team.
  bool get isAwaitingSupport =>
      status == SupportRequestStatus.open && awaitingReply;

  /// Whether the support team has answered and the thread is still open — the
  /// state the participant is being invited to reply into.
  bool get isAnswered =>
      status == SupportRequestStatus.open && !awaitingReply;

  bool get isResolved => status == SupportRequestStatus.resolved;

  factory SupportRequest.fromJson(Map<String, dynamic> json) {
    final lastMessageSenderRole = SupportSenderRole.fromJson(
      json['lastMessageSenderRole'] as String?,
    );
    return SupportRequest(
      id: json['id'] as String? ?? '',
      requesterId: json['requesterId'] as String? ?? '',
      requesterName: json['requesterName'] as String? ?? '',
      requesterImage: json['requesterImage'] as String?,
      subject: json['subject'] as String? ?? '',
      status: SupportRequestStatus.fromJson(json['status'] as String?),
      // Documents written before the flag existed still read correctly: fall
      // back to the same rule the flag encodes.
      awaitingReply:
          json['awaitingReply'] as bool? ??
          lastMessageSenderRole == SupportSenderRole.user,
      lastMessageText: json['lastMessageText'] as String? ?? '',
      lastMessageAt: (json['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderRole: lastMessageSenderRole,
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (json['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: json['resolvedBy'] as String?,
    );
  }

  /// The Firestore shape written when a participant opens a request.
  ///
  /// The server sets the timestamps and the first message's snapshot, so the
  /// caller can't skew them; this is only the identity of the request and the
  /// state a new one must start in — open, waiting on an admin, unresolved,
  /// which is exactly what the security rules check on create.
  static Map<String, dynamic> openFields({
    required String requesterId,
    required String requesterName,
    String? requesterImage,
    required String subject,
  }) => {
    'requesterId': requesterId,
    'requesterName': requesterName,
    if (requesterImage != null && requesterImage.isNotEmpty)
      'requesterImage': requesterImage,
    'subject': subject,
    'status': SupportRequestStatus.open.jsonValue,
    'awaitingReply': true,
    'messageCount': 0,
    'resolvedAt': null,
    'resolvedBy': null,
  };

  /// The fields to write onto the request when a message is appended to it.
  ///
  /// This is the ONE place the denormalized snapshot is derived — the app and
  /// the panel both go through it (the panel's twin lives in
  /// `types/support.ts`), so the two cannot disagree about what "unresponded"
  /// means.
  ///
  /// A participant writing into a resolved thread reopens it and clears the
  /// resolution, because from their side the matter evidently isn't closed. An
  /// admin replying never changes the status: closing out stays explicit.
  ///
  /// Timestamps are [FieldValue.serverTimestamp] rather than the device clock,
  /// because [lastMessageAt] orders the queue across two apps and several
  /// machines — a phone with a skewed clock must not be able to jump a thread to
  /// the top of an admin's list.
  static Map<String, dynamic> patchForMessage({
    required SupportSenderRole senderRole,
    required String message,
    required SupportRequestStatus currentStatus,
  }) {
    final fromUser = senderRole == SupportSenderRole.user;
    return {
      'awaitingReply': fromUser,
      'lastMessageText': previewText(message),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderRole': senderRole.jsonValue,
      'updatedAt': FieldValue.serverTimestamp(),
      'messageCount': FieldValue.increment(1),
      if (fromUser && currentStatus == SupportRequestStatus.resolved) ...{
        'status': SupportRequestStatus.open.jsonValue,
        'resolvedAt': null,
        'resolvedBy': null,
      },
    };
  }

  /// Collapse whitespace and clip to [max], for a single-line list preview.
  static String previewText(String text, {int max = previewMaxLength}) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length > max ? '${flat.substring(0, max - 1)}…' : flat;
  }

  /// How much of a message is denormalized onto the request as a preview.
  static const int previewMaxLength = 200;

  /// The longest a subject may be. Mirrors the panel and the security rules.
  static const int subjectMaxLength = 140;
}

/// One message in a thread.
///
/// [senderName] is recorded for both sides, but for an admin it is internal
/// only — the app renders admin replies as coming from the support team rather
/// than from the individual who typed them (see [isFromSupport]).
class SupportMessage {
  final String id;

  /// The parent request's id and the owning event's id, denormalized onto every
  /// message — the same reason the community's comments carry them: a message
  /// stays meaningful on its own, and the rules check both on create.
  final String requestId;
  final String eventId;

  final SupportSenderRole senderRole;

  /// The uid of whoever sent it — the participant, or the replying admin.
  final String senderId;

  /// Display name at send time. Internal for admin messages.
  final String senderName;

  /// Plain text body. Not localised — the thread is a single conversation.
  final String message;

  /// Null only between the local write and the server resolving its timestamp,
  /// which is what an optimistic row on screen looks like.
  final DateTime? createdAt;

  const SupportMessage({
    required this.id,
    required this.requestId,
    required this.eventId,
    required this.senderRole,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  /// Whether this came from the event's support team rather than the
  /// participant — what decides which side of the thread it is drawn on.
  bool get isFromSupport => senderRole == SupportSenderRole.admin;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as String? ?? '',
      requestId: json['requestId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      senderRole: SupportSenderRole.fromJson(json['senderRole'] as String?),
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// The Firestore shape written on create. `createdAt` is set by the
  /// repository with a server timestamp, so it isn't here.
  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'eventId': eventId,
    'senderRole': senderRole.jsonValue,
    'senderId': senderId,
    'senderName': senderName,
    'message': message,
  };

  /// The longest a message may be. Mirrors the panel and the security rules.
  static const int messageMaxLength = 4000;
}
