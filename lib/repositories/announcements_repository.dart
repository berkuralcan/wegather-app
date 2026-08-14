import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/access_model.dart';
import '../models/announcement_model.dart';

/// Reads for an event's announcements. Announcements live in a subcollection of
/// their event — `events/{eventId}/announcements/{id}` — and inherit its access:
/// anyone who can read the event can read its announcements. Writes happen in the
/// admin panel only (`composables/useAnnouncements.ts`).
class AnnouncementsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _announcementsCollection(
    String eventId,
  ) => _firestore
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.announcements);

  /// Every announcement for an event, newest first.
  Future<List<AnnouncementModel>> getAnnouncements(String eventId) async {
    final snapshot = await _announcementsCollection(
      eventId,
    ).orderBy('createdAt', descending: true).get();
    // The document id wins over any stale `id` written into the body.
    return snapshot.docs
        .map((doc) => AnnouncementModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// A single announcement, or null if it doesn't exist.
  Future<AnnouncementModel?> getAnnouncement(
    String eventId,
    String announcementId,
  ) async {
    final doc = await _announcementsCollection(
      eventId,
    ).doc(announcementId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return AnnouncementModel.fromJson({...data, 'id': doc.id});
  }
}
