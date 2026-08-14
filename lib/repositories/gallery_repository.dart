import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/access_model.dart';
import '../models/gallery_media.dart';

/// The event gallery in Firestore — `events/{eventId}/gallery/{mediaId}`.
///
/// This is the only collection the app writes to. Reads inherit the event's
/// access like every other subcollection; creates are allowed for any user with
/// access to the event as long as the document names them as the uploader, and
/// the only update anyone may make is raising the report flag. Both rules live
/// in the admin panel's `firestore.rules`.
class GalleryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _galleryCollection(
    String eventId,
  ) => _firestore
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.gallery);

  /// Every piece of media in an event's gallery, newest first.
  Future<List<GalleryMedia>> getMedia(String eventId) async {
    final snapshot = await _galleryCollection(
      eventId,
    ).orderBy('uploadedAt', descending: true).get();
    // The document id wins over any stale `id` written into the body.
    return snapshot.docs
        .map((doc) => GalleryMedia.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Records an uploaded file in the gallery and returns its new id.
  ///
  /// The file itself is already in Storage by this point — see
  /// `StorageService.uploadGalleryMedia`. `uploadedAt` is the server's clock,
  /// not the device's, because it is what the gallery is ordered and grouped by.
  Future<String> addMedia(String eventId, GalleryMedia media) async {
    final doc = await _galleryCollection(
      eventId,
    ).add({...media.toJson(), 'uploadedAt': FieldValue.serverTimestamp()});
    return doc.id;
  }

  /// Flags a piece of media for moderation.
  ///
  /// [reason] is whatever the reporter typed, which may be nothing. The report
  /// is deliberately not a counter or a list: a single flag is all the admin
  /// panel needs to surface the media for review, and it is the only field
  /// shape the security rules let a non-owner write.
  Future<void> reportMedia(
    String eventId,
    String mediaId, {
    required String reportedBy,
    String? reason,
  }) {
    return _galleryCollection(eventId).doc(mediaId).update({
      'isReported': true,
      'reportedBy': reportedBy,
      'reportedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.trim().isNotEmpty)
        'reportReason': reason.trim(),
    });
  }
}
