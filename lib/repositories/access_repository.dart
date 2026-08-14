import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/access_model.dart';
import '../models/event_model.dart';

/// Firestore reads for the access model. Unlike [BaseRepository] subclasses
/// this spans several collections, because "what may this user see?" is a
/// question about the junctions as much as about the entities.
///
/// Security rules are the real enforcement boundary — these queries just avoid
/// asking for what a user can't see. That is not only about UI honesty: a
/// Firestore query fails *entirely* if any returned document is disallowed, so
/// an app user must fetch their events **by id** rather than listing the
/// `events` collection. See the `wegather-access-model` skill.
class AccessRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// The signed-in user's `users/{uid}` document, or null if they have none.
  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(Collections.users).doc(uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return AppUser.fromJson(doc.id, data);
  }

  /// Company ids the user holds an admin role in (via `user_company_roles`).
  Future<List<String>> getAdminCompanyIds(String uid) async {
    final snapshot = await _firestore
        .collection(Collections.userCompanyRoles)
        .where('userId', isEqualTo: uid)
        .get();
    return snapshot.docs
        .map((doc) => doc.data()['companyId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// The user's `user_event_access` rows — the events an app user was granted.
  Future<List<UserEventAccess>> getEventAccessRows(String uid) async {
    final snapshot = await _firestore
        .collection(Collections.userEventAccess)
        .where('userId', isEqualTo: uid)
        .get();
    return snapshot.docs
        .map((doc) => UserEventAccess.fromJson(doc.data()))
        .toList();
  }

  /// Every event (super-admin view).
  Future<List<EventModel>> getAllEvents() async {
    final snapshot = await _firestore.collection(Collections.events).get();
    return snapshot.docs
        .map((doc) => EventModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  /// Events belonging to the given companies (admin view).
  Future<List<EventModel>> getEventsForCompanies(
    List<String> companyIds,
  ) async {
    final ids = companyIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const [];

    final events = <EventModel>[];
    for (final batch in _chunk(ids, 10)) {
      final snapshot = await _firestore
          .collection(Collections.events)
          .where('companyId', whereIn: batch)
          .get();
      events.addAll(
        snapshot.docs.map((doc) => EventModel.fromJson(doc.id, doc.data())),
      );
    }
    return events;
  }

  /// Events fetched by id (app-user view — the only shape rules allow them).
  Future<List<EventModel>> getEventsByIds(List<String> eventIds) async {
    final ids = eventIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const [];

    final events = <EventModel>[];
    for (final batch in _chunk(ids, 10)) {
      final snapshot = await _firestore
          .collection(Collections.events)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      events.addAll(
        snapshot.docs.map((doc) => EventModel.fromJson(doc.id, doc.data())),
      );
    }
    return events;
  }

  /// A single event, or null if it doesn't exist / isn't readable.
  Future<EventModel?> getEventById(String eventId) async {
    if (eventId.isEmpty) return null;
    final doc = await _firestore
        .collection(Collections.events)
        .doc(eventId)
        .get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return EventModel.fromJson(doc.id, data);
  }

  /// Split [items] into batches — Firestore's `whereIn` takes at most 10.
  static List<List<T>> _chunk<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < items.length; i += size) {
      chunks.add(
        items.sublist(i, i + size > items.length ? items.length : i + size),
      );
    }
    return chunks;
  }
}
