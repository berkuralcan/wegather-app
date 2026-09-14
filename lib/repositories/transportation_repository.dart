import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/access_model.dart';
import '../models/transportation_model.dart';

/// The Transportation feature in Firestore. Three subcollections hang off an
/// event (see `models/transportation_model.dart`):
///
///   * `events/{eventId}/destinations/{id}` — the places transfers run between,
///   * `events/{eventId}/internalTransportations/{id}` — the scheduled transfers,
///   * `.../internalTransportations/{id}/bookings/{uid}` — one doc per booked
///     seat, keyed by the booking user's uid.
///
/// The first two are authored in the admin panel (`composables/useTransportation.ts`)
/// and read-only here. The bookings are the app's: a user takes a seat by
/// writing their own document, which — being keyed by their uid — is idempotent.
/// The panel only reads them, for its occupancy summary. Both sides are covered
/// by the rules in the panel's `firestore.rules`.
class TransportationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _destinationsCollection(
    String eventId,
  ) => _firestore
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.destinations);

  CollectionReference<Map<String, dynamic>> _transportationsCollection(
    String eventId,
  ) => _firestore
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.internalTransportations);

  CollectionReference<Map<String, dynamic>> _bookingsCollection(
    String eventId,
    String transportationId,
  ) => _transportationsCollection(
    eventId,
  ).doc(transportationId).collection(Collections.bookings);

  /// Every destination of an event, ordered by name — the from/to pickers.
  Future<List<DestinationModel>> getDestinations(String eventId) async {
    final snapshot = await _destinationsCollection(
      eventId,
    ).orderBy('name').get();
    // The document id wins over any stale `id` written into the body.
    return snapshot.docs
        .map((doc) => DestinationModel.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  /// The transfers leaving [fromId] for [destinationId] on [day], earliest
  /// first.
  ///
  /// [day] is matched exactly against the stored local-midnight timestamp, which
  /// is how the panel writes it — a transfer belongs to one calendar day, and
  /// its departure is the separate "HH:MM" `time` field. The three equality
  /// filters plus the ordered `time` need the composite index declared in the
  /// panel's `firestore.indexes.json`.
  Future<List<InternalTransportationModel>> searchTransportations({
    required String eventId,
    required String fromId,
    required String destinationId,
    required DateTime day,
  }) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final snapshot = await _transportationsCollection(eventId)
        .where('from.id', isEqualTo: fromId)
        .where('destination.id', isEqualTo: destinationId)
        .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('time')
        .get();
    return snapshot.docs
        .map((doc) => InternalTransportationModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  /// How many seats of a transfer are taken.
  ///
  /// A count aggregation rather than reading the documents: the app only needs
  /// the number, and this stays one cheap read however full the transfer is.
  Future<int> countBookings(String eventId, String transportationId) async {
    final snapshot = await _bookingsCollection(
      eventId,
      transportationId,
    ).count().get();
    return snapshot.count ?? 0;
  }

  /// Whether [userId] already holds a seat on a transfer.
  Future<bool> hasBooking(
    String eventId,
    String transportationId,
    String userId,
  ) async {
    final doc = await _bookingsCollection(
      eventId,
      transportationId,
    ).doc(userId).get();
    return doc.exists;
  }

  /// Takes a seat for [userId] on a transfer.
  ///
  /// The document is keyed by the uid, so booking twice is a no-op rather than a
  /// second seat. `createdAt` is the server's clock, not the device's, since it
  /// is what the panel orders the passenger list by.
  Future<void> book(
    String eventId,
    String transportationId, {
    required String userId,
    String? userName,
  }) {
    return _bookingsCollection(eventId, transportationId).doc(userId).set({
      'userId': userId,
      if (userName != null && userName.trim().isNotEmpty)
        'userName': userName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
