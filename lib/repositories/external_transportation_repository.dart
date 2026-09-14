import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/access_model.dart';
import '../models/external_transportation_model.dart';
import '../models/transportation_model.dart';

/// The **external** travel feature in Firestore — flights to the event city and
/// home again. Four collections hang off an event (see
/// `models/external_transportation_model.dart`):
///
///   * `events/{eventId}/travelDestinations/{id}` — origin cities/airports,
///   * `events/{eventId}/externalTransportations/{id}` — published flights,
///   * `.../externalTransportations/{id}/seats/{uid}` — the countable seat
///     mirror on a capacity-limited flight,
///   * `events/{eventId}/externalTransportationBookings/{uid}` — the request.
///
/// The first two are authored in the admin panel (`composables/useTravel.ts`)
/// and read-only here. The last two are the app's to write, within the limits
/// the panel's `firestore.rules` set: a request may only be created or changed
/// by the user it belongs to, and only while its status is still `submitted`.
class ExternalTransportationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _destinationsCollection(
    String eventId,
  ) => _firestore
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.travelDestinations);

  CollectionReference<Map<String, dynamic>> _transportationsCollection(
    String eventId,
  ) => _firestore
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.externalTransportations);

  CollectionReference<Map<String, dynamic>> _seatsCollection(
    String eventId,
    String transportationId,
  ) => _transportationsCollection(
    eventId,
  ).doc(transportationId).collection(Collections.seats);

  CollectionReference<Map<String, dynamic>> _bookingsCollection(
    String eventId,
  ) => _firestore
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.externalTransportationBookings);

  /// Every travel destination of an event, ordered by name.
  Future<List<DestinationModel>> getTravelDestinations(String eventId) async {
    final snapshot = await _destinationsCollection(
      eventId,
    ).orderBy('name').get();
    // The document id wins over any stale `id` written into the body.
    return snapshot.docs
        .map((doc) => DestinationModel.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  /// Every published flight of an event, in departure order.
  ///
  /// Only `date` is ordered server-side. `time` is optional on a flight, and a
  /// Firestore `orderBy` silently drops documents that lack the field, so
  /// ordering by it would make a timeless flight vanish from the picker
  /// entirely. The within-day sort happens here instead — the panel's
  /// `listExternalTransportations` does the same, for the same reason.
  Future<List<ExternalTransportationModel>> getTransportations(
    String eventId,
  ) async {
    final snapshot = await _transportationsCollection(
      eventId,
    ).orderBy('date').get();
    final flights = snapshot.docs
        .map(
          (doc) => ExternalTransportationModel.fromJson(doc.id, doc.data()),
        )
        .toList();
    flights.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return (a.time ?? '').compareTo(b.time ?? '');
    });
    return flights;
  }

  /// How many seats are taken on a flight.
  ///
  /// A count aggregation over the seat mirror rather than the requests: the
  /// requests carry passport numbers and are readable only by their owner and
  /// the event's managers, so this is the one number the app can actually get.
  Future<int> countSeats(String eventId, String transportationId) async {
    final snapshot = await _seatsCollection(
      eventId,
      transportationId,
    ).count().get();
    return snapshot.count ?? 0;
  }

  /// Takes a seat on a flight for [userId], keyed by the uid so it is
  /// idempotent — re-submitting an unchanged request is a no-op, not a second
  /// seat.
  Future<void> takeSeat(
    String eventId,
    String transportationId, {
    required String userId,
    String? userName,
  }) {
    return _seatsCollection(eventId, transportationId).doc(userId).set({
      'userId': userId,
      if (userName != null && userName.trim().isNotEmpty)
        'userName': userName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Gives up a seat — used when an edit drops a leg the user had chosen.
  Future<void> releaseSeat(
    String eventId,
    String transportationId, {
    required String userId,
  }) {
    return _seatsCollection(eventId, transportationId).doc(userId).delete();
  }

  /// The signed-in user's travel request, or null if they haven't made one.
  Future<ExternalTransportationBookingModel?> getBooking(
    String eventId,
    String userId,
  ) async {
    final doc = await _bookingsCollection(eventId).doc(userId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return ExternalTransportationBookingModel.fromJson(doc.id, data);
  }

  /// Creates or updates the user's request.
  ///
  /// `createdAt` is written only on the first save, so an edit doesn't reset the
  /// queue position the panel orders by; `updatedAt` moves every time. Both come
  /// from the server's clock rather than the device's.
  ///
  /// An edit merges rather than overwrites, so it leaves the panel's own fields
  /// — `adminNote`, and the ticket results the panel writes into `legs` — where
  /// they are. The one thing merging cannot do is remove a field, so a switch to
  /// "I'll make my own way" deletes the passenger block outright: leaving a
  /// passport number behind for someone who opted out of flying is not an
  /// acceptable way to fail.
  Future<void> saveBooking(
    String eventId,
    ExternalTransportationBookingModel booking, {
    required bool isNew,
  }) {
    final isSelf = booking.type == TravelType.self;
    return _bookingsCollection(eventId).doc(booking.userId).set({
      ...booking.toJson(),
      // Only on an edit: `FieldValue.delete()` is rejected outright by a
      // non-merging set, and a brand-new request has nothing to clear anyway.
      if (isSelf && !isNew) 'passenger': FieldValue.delete(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: !isNew));
  }
}
