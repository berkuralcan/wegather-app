import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/external_transportation_model.dart';
import '../services/external_transportation_service.dart';
import 'access_providers.dart';
import 'auth_providers.dart';

final externalTransportationServiceProvider =
    Provider<ExternalTransportationService>(
      (ref) => ExternalTransportationService(),
    );

/// The flights the selected event has published, split by leg and each carrying
/// its seat count and whether the viewer is on it.
///
/// `autoDispose` for the same reason the internal transfers list is: the screen
/// is pushed on the root navigator, so leaving it drops the last listener and
/// re-entering refetches — which is how an admin's edits show up without a
/// restart. Submitting a request invalidates this, so the seat counts a user
/// sees after saving are the ones their own booking just changed.
final flightOptionsProvider = FutureProvider.autoDispose<FlightOptions>((
  ref,
) async {
  final eventId = ref.watch(selectedEventIdProvider);
  if (eventId == null) {
    return const FlightOptions(arrivals: [], departures: []);
  }
  return ref
      .watch(externalTransportationServiceProvider)
      .getFlightOptions(
        eventId: eventId,
        viewerId: ref.watch(currentUserProvider)?.uid ?? '',
      );
});

/// The viewer's own travel request, or null while they haven't made one — the
/// single thing that decides which of the screen's states is shown.
///
/// Invalidated on submit so the screen re-reads what was actually stored rather
/// than trusting what it sent.
final myTravelRequestProvider =
    FutureProvider.autoDispose<ExternalTransportationBookingModel?>((ref) async {
      final eventId = ref.watch(selectedEventIdProvider);
      final viewerId = ref.watch(currentUserProvider)?.uid;
      if (eventId == null || viewerId == null) return null;
      return ref
          .watch(externalTransportationServiceProvider)
          .getMyBooking(eventId: eventId, viewerId: viewerId);
    });
