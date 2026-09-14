import '../models/external_transportation_model.dart';
import '../models/transportation_model.dart';
import '../repositories/external_transportation_repository.dart';

/// A published flight as the reservation screen needs to show it: the flight
/// itself, how many seats are taken, and whether the viewer is already on it.
///
/// The Dart counterpart of the panel's `ExternalTransportationOccupancy`, with
/// the viewer's own seat added — the panel summarises a flight for a manager,
/// the app also has to know whether the person looking at it is on it.
class FlightAvailability {
  const FlightAvailability({
    required this.transportation,
    required this.taken,
    required this.isTakenByViewer,
  });

  final ExternalTransportationModel transportation;

  /// Seats taken, across every participant. On a flight with no limit this is
  /// simply demand so far.
  final int taken;

  /// Whether the viewer's current request already includes this flight.
  final bool isTakenByViewer;

  /// Seats still free, or null when the flight has no limit.
  int? get seatsLeft => transportation.seatsLeft(taken);

  /// Whether a capacity-limited flight has run out. Unlimited is never full.
  bool get isFullyBooked => transportation.isFullAt(taken);

  /// Whether the viewer may still choose this flight: it has room, or they are
  /// already on it (so re-saving an unchanged request is never refused).
  bool get canChoose => !isFullyBooked || isTakenByViewer;
}

/// Raised when a flight could not be taken because it filled up between the
/// picker and the tap. The screen turns this into a message rather than a
/// generic failure.
class FlightFullException implements Exception {
  const FlightFullException(this.flight);

  final ExternalTransportationModel flight;

  @override
  String toString() => 'FlightFullException: ${flight.id} has no seats left';
}

/// Everything the reservation screen needs to render its form in one value: the
/// published flights split by which half of the journey they cover, and the
/// destinations each half can be reached from.
///
/// The screen's two pickers are "where are you flying from" and "which flight",
/// so the flights are grouped by the participant's own end of the journey —
/// which is [ExternalTransportationModel.from] on an arrival (their home city)
/// and [ExternalTransportationModel.destination] on a departure (where they are
/// heading back to). [homeSideOf] is the single place that asymmetry lives.
class FlightOptions {
  const FlightOptions({required this.arrivals, required this.departures});

  /// Flights that bring a participant to the event, in departure order.
  final List<FlightAvailability> arrivals;

  /// Flights that take them home again, in departure order.
  final List<FlightAvailability> departures;

  bool get isEmpty => arrivals.isEmpty && departures.isEmpty;

  /// The participant's own end of a flight — the city they pick in the form.
  static DestinationModel homeSideOf(ExternalTransportationModel flight) =>
      flight.kind == TravelLegKind.arrival
      ? flight.from
      : flight.destination;

  /// The distinct places one half of the journey can be flown from (arrival) or
  /// to (departure), in the order the flights themselves came back.
  ///
  /// Deduplicated by destination id, because many flights share one origin and
  /// the picker should offer each city once.
  List<DestinationModel> destinationsFor(TravelLegKind kind) {
    final seen = <String>{};
    final places = <DestinationModel>[];
    for (final availability in _of(kind)) {
      final place = homeSideOf(availability.transportation);
      if (place.id.isEmpty || !seen.add(place.id)) continue;
      places.add(place);
    }
    return places;
  }

  /// The flights of one half of the journey that start (or end) at a place.
  List<FlightAvailability> flightsFor(TravelLegKind kind, String placeId) => _of(
    kind,
  ).where((a) => homeSideOf(a.transportation).id == placeId).toList();

  List<FlightAvailability> _of(TravelLegKind kind) =>
      kind == TravelLegKind.arrival ? arrivals : departures;
}

/// Business logic for external travel: reading the published flights, and
/// submitting or revising the participant's own request.
class ExternalTransportationService {
  final ExternalTransportationRepository _repository =
      ExternalTransportationRepository();

  /// The flights on offer, each with its occupancy, split by leg.
  ///
  /// Seat counts are fetched in parallel — one cheap count aggregation per
  /// flight, and an event publishes a handful, not thousands. A flight with no
  /// capacity is counted too: the number is shown as demand rather than as a
  /// limit, and it costs the same read either way.
  Future<FlightOptions> getFlightOptions({
    required String eventId,
    required String viewerId,
  }) async {
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }

    final flights = await _repository.getTransportations(eventId);
    // The viewer's own seats come from their request rather than from a lookup
    // per flight: one read instead of N, and the request is the source of truth
    // for what they actually asked for.
    final booking = viewerId.isEmpty
        ? null
        : await _repository.getBooking(eventId, viewerId);
    final viewerFlightIds = booking?.transportationIds ?? const <String>{};

    final availabilities = await Future.wait(
      flights.map((flight) async {
        final taken = await _repository.countSeats(eventId, flight.id);
        return FlightAvailability(
          transportation: flight,
          taken: taken,
          isTakenByViewer: viewerFlightIds.contains(flight.id),
        );
      }),
    );

    return FlightOptions(
      arrivals: availabilities
          .where((a) => a.transportation.kind == TravelLegKind.arrival)
          .toList(),
      departures: availabilities
          .where((a) => a.transportation.kind == TravelLegKind.departure)
          .toList(),
    );
  }

  /// The viewer's own request, or null if they haven't made one.
  Future<ExternalTransportationBookingModel?> getMyBooking({
    required String eventId,
    required String viewerId,
  }) {
    if (eventId.isEmpty || viewerId.isEmpty) {
      throw ArgumentError('Event ID and user ID cannot be empty');
    }
    return _repository.getBooking(eventId, viewerId);
  }

  /// Submits — or revises — the viewer's travel request.
  ///
  /// Order matters here. The request document is written FIRST and the seat
  /// mirror second, because the request is the source of truth: if the seat
  /// writes fail, an admin still sees the request and the count is merely low,
  /// whereas the reverse would leave seats held by a request nobody can see.
  ///
  /// Capacity is checked immediately before the write and is a check, not a
  /// lock — security rules cannot count a subcollection, so two people taking
  /// the last seat at the same moment can both succeed. The panel's occupancy
  /// view is where that surfaces. A flight the viewer is *already* on never
  /// fails this check, so re-saving an unchanged request cannot lock them out
  /// of their own seat.
  ///
  /// Throws [FlightFullException] naming the flight that filled up.
  Future<ExternalTransportationBookingModel> submit({
    required String eventId,
    required String viewerId,
    required TravelType type,
    TravelPassengerModel? passenger,
    List<ExternalTransportationModel> flights = const [],
    String? viewerName,
    String? viewerEmail,
    String? notes,
  }) async {
    if (eventId.isEmpty || viewerId.isEmpty) {
      throw ArgumentError('Event ID and user ID cannot be empty');
    }

    final existing = await _repository.getBooking(eventId, viewerId);
    if (existing != null && !existing.isEditable) {
      throw StateError('A request that is no longer submitted cannot be edited');
    }
    final heldBefore = existing?.transportationIds ?? const <String>{};

    final chosen = type == TravelType.flight
        ? flights
        : const <ExternalTransportationModel>[];

    for (final flight in chosen) {
      if (heldBefore.contains(flight.id) || !flight.hasSeatLimit) continue;
      final taken = await _repository.countSeats(eventId, flight.id);
      if (flight.isFullAt(taken)) throw FlightFullException(flight);
    }

    final booking = ExternalTransportationBookingModel(
      userId: viewerId,
      userName: viewerName,
      userEmail: viewerEmail,
      type: type,
      passenger: type == TravelType.flight ? passenger : null,
      legs: chosen
          .map(ExternalTransportationLegModel.fromTransportation)
          .toList(),
      // Always the app's own state: the panel owns the move to booked, and the
      // rules refuse a participant setting anything else.
      status: TravelStatus.submitted,
      notes: notes,
    );

    await _repository.saveBooking(
      eventId,
      booking,
      isNew: existing == null,
    );

    await _syncSeats(
      eventId: eventId,
      viewerId: viewerId,
      viewerName: viewerName,
      heldBefore: heldBefore,
      heldNow: booking.transportationIds,
    );

    return booking;
  }

  /// Brings the seat mirror in line with the request that was just saved:
  /// take a seat on every newly chosen flight, give up the ones dropped.
  ///
  /// Best-effort by design. The request is already saved at this point, so a
  /// failure here must not surface as "your request failed" — it leaves the
  /// count slightly off, which the panel can see and correct, and which the
  /// next save reconciles.
  Future<void> _syncSeats({
    required String eventId,
    required String viewerId,
    required String? viewerName,
    required Set<String> heldBefore,
    required Set<String> heldNow,
  }) async {
    Future<void> ignoringFailure(Future<void> Function() write) async {
      try {
        await write();
      } catch (_) {
        // Deliberately swallowed — see the doc comment.
      }
    }

    await Future.wait([
      for (final id in heldNow.difference(heldBefore))
        ignoringFailure(
          () => _repository.takeSeat(
            eventId,
            id,
            userId: viewerId,
            userName: viewerName,
          ),
        ),
      for (final id in heldBefore.difference(heldNow))
        ignoringFailure(
          () => _repository.releaseSeat(eventId, id, userId: viewerId),
        ),
    ]);
  }
}
