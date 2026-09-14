import '../models/transportation_model.dart';
import '../repositories/transportation_repository.dart';

/// A transfer as the booking screen needs to show it: the transfer itself, how
/// many of its seats are taken, and whether the viewer is already on it.
///
/// The Dart counterpart of the panel's `TransportationOccupancy`
/// (`types/transportation.ts`), with the viewer's own booking added — the panel
/// summarises a transfer for a manager, the app also has to know whether the
/// person looking at it holds one of those seats.
class TransferAvailability {
  const TransferAvailability({
    required this.transportation,
    required this.booked,
    required this.isBookedByViewer,
  });

  final InternalTransportationModel transportation;

  /// Seats taken, across every user.
  final int booked;

  /// Whether the viewer already holds one of those seats.
  final bool isBookedByViewer;

  /// Seats still free.
  int get seatsLeft => availableSeats(transportation.capacity, booked);

  /// Whether every seat is taken.
  bool get isFullyBooked => isFull(transportation.capacity, booked);

  /// Whether the viewer may still take a seat: the transfer has room and they
  /// are not already on it.
  bool get canBook => !isFullyBooked && !isBookedByViewer;
}

/// Raised when a seat could not be taken because the transfer filled up between
/// the search and the tap. The screen turns this into a message rather than a
/// generic failure.
class TransferFullException implements Exception {
  const TransferFullException();

  @override
  String toString() => 'TransferFullException: the transfer has no seats left';
}

/// Business logic around an event's transfers: searching for the ones that
/// match a from/to/day, and taking a seat on one.
class TransportationService {
  final TransportationRepository _repository = TransportationRepository();

  /// The destinations a transfer can run between, for the from/to pickers.
  Future<List<DestinationModel>> getDestinations(String eventId) {
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }
    return _repository.getDestinations(eventId);
  }

  /// The transfers matching a from/to pair on a day, each paired with its
  /// occupancy so the list can show a seat button or "full" straight away.
  ///
  /// The transfers' occupancy is fetched in parallel — two cheap operations per
  /// transfer (a count aggregation, and the lookup of the viewer's own booking
  /// by uid), and a search only ever returns one day's departures.
  Future<List<TransferAvailability>> searchTransfers({
    required String eventId,
    required String fromId,
    required String destinationId,
    required DateTime day,
    required String viewerId,
  }) async {
    if (eventId.isEmpty || fromId.isEmpty || destinationId.isEmpty) {
      throw ArgumentError('Event ID, origin and destination cannot be empty');
    }

    final transfers = await _repository.searchTransportations(
      eventId: eventId,
      fromId: fromId,
      destinationId: destinationId,
      day: day,
    );

    return Future.wait(
      transfers.map((transfer) async {
        final booked = await _repository.countBookings(eventId, transfer.id);
        final isBookedByViewer = viewerId.isEmpty
            ? false
            : await _repository.hasBooking(eventId, transfer.id, viewerId);
        return TransferAvailability(
          transportation: transfer,
          booked: booked,
          isBookedByViewer: isBookedByViewer,
        );
      }),
    );
  }

  /// Takes a seat on a transfer for [viewerId].
  ///
  /// The seat count is re-read immediately before the write, so a transfer that
  /// filled up while the user was looking at the list fails with a
  /// [TransferFullException] instead of silently overbooking. This is a check,
  /// not a lock: security rules cannot count a subcollection, so two users
  /// taking the last seat at the same moment can still both succeed. The panel's
  /// occupancy summary is where that surfaces.
  Future<void> book({
    required String eventId,
    required InternalTransportationModel transfer,
    required String viewerId,
    String? viewerName,
  }) async {
    if (eventId.isEmpty || transfer.id.isEmpty || viewerId.isEmpty) {
      throw ArgumentError('Event ID, transfer ID and user ID cannot be empty');
    }

    // Booking is keyed by uid, so re-booking an existing seat is a no-op — but
    // it must not be refused as "full" either, hence the check for it first.
    final alreadyBooked = await _repository.hasBooking(
      eventId,
      transfer.id,
      viewerId,
    );
    if (!alreadyBooked) {
      final booked = await _repository.countBookings(eventId, transfer.id);
      if (isFull(transfer.capacity, booked)) {
        throw const TransferFullException();
      }
    }

    await _repository.book(
      eventId,
      transfer.id,
      userId: viewerId,
      userName: viewerName,
    );
  }
}
