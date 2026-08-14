import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/access_model.dart';
import '../models/activity_model.dart';

/// Reads for an event's schedule. Activities live in a subcollection of their
/// event — `events/{eventId}/activities/{activityId}` — and inherit its access:
/// anyone who can read the event can read its activities. Writes happen in the
/// admin panel only (`composables/useActivities.ts`).
///
/// The event's roster (`events/{eventId}/participants`) is read here too. The
/// schedule itself never needs it — activities embed a snapshot of everyone
/// assigned to them — but a page that wants the *whole* roster, rather than one
/// activity's slice of it, has to go to the collection itself.
class ActivitiesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _activitiesCollection(
    String eventId,
  ) => _firestore
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.activities);

  CollectionReference<Map<String, dynamic>> _participantsCollection(
    String eventId,
  ) => _firestore
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.participants);

  /// Every activity of an event, unordered — [ActivitiesService] sorts them.
  ///
  /// Deliberately not an `orderBy('startDateTime')` query: Firestore drops
  /// documents that are missing the ordered field, and a schedule that silently
  /// hides an activity is worse than one that sorts it to the front.
  Future<List<ActivityModel>> getActivities(String eventId) async {
    final snapshot = await _activitiesCollection(eventId).get();
    // The document id wins over any stale `id` written into the body.
    return snapshot.docs
        .map((doc) => ActivityModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  /// A single activity, or null if it doesn't exist.
  Future<ActivityModel?> getActivity(String eventId, String activityId) async {
    final doc = await _activitiesCollection(eventId).doc(activityId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return ActivityModel.fromJson(doc.id, data);
  }

  /// The event's whole roster, unordered — [ActivitiesService] sorts it.
  ///
  /// Not an `orderBy('name')` query, for the same reason the activities aren't
  /// ordered in Firestore: a roster entry missing the field would be dropped
  /// from the result rather than merely sorted oddly.
  Future<List<ParticipantModel>> getParticipants(String eventId) async {
    final snapshot = await _participantsCollection(eventId).get();
    // The document id wins over any stale `id` written into the body.
    return snapshot.docs
        .map((doc) => ParticipantModel.fromJson(doc.data(), id: doc.id))
        .toList();
  }
}
