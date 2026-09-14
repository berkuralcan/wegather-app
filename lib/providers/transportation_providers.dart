import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transportation_model.dart';
import '../services/transportation_service.dart';
import 'access_providers.dart';
import 'auth_providers.dart';

final transportationServiceProvider = Provider<TransportationService>(
  (ref) => TransportationService(),
);

/// The destinations of the currently selected event — what the from/to pickers
/// offer. Empty while no event is selected.
///
/// `autoDispose` for the same reason the tips list is: the screen is pushed on
/// the root navigator, so leaving it drops the last listener and re-entering
/// refetches, which is how admin-panel edits show up without a restart.
final destinationsProvider = FutureProvider.autoDispose<List<DestinationModel>>(
  (ref) async {
    final eventId = ref.watch(selectedEventIdProvider);
    if (eventId == null) return const [];
    return ref.watch(transportationServiceProvider).getDestinations(eventId);
  },
);

/// A from/to/day the user has searched for. Value type so it can key
/// [transferSearchProvider] — two identical searches share one result.
class TransferQuery {
  const TransferQuery({
    required this.fromId,
    required this.destinationId,
    required this.day,
  });

  final String fromId;
  final String destinationId;

  /// The calendar day, normalised to local midnight by the constructor callers
  /// (the screen's date picker hands over a midnight date already).
  final DateTime day;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferQuery &&
          other.fromId == fromId &&
          other.destinationId == destinationId &&
          other.day == day;

  @override
  int get hashCode => Object.hash(fromId, destinationId, day);
}

/// The transfers matching a search, each with its occupancy and whether the
/// viewer is on it.
///
/// `autoDispose` so a search is dropped once nothing displays it, and
/// `family` so the screen simply watches the query it submitted. Booking
/// invalidates this provider for that query, which is what re-renders the row
/// as taken.
final transferSearchProvider = FutureProvider.autoDispose
    .family<List<TransferAvailability>, TransferQuery>((ref, query) async {
      final eventId = ref.watch(selectedEventIdProvider);
      if (eventId == null) return const [];
      final viewerId = ref.watch(currentUserProvider)?.uid ?? '';
      return ref
          .watch(transportationServiceProvider)
          .searchTransfers(
            eventId: eventId,
            fromId: query.fromId,
            destinationId: query.destinationId,
            day: query.day,
            viewerId: viewerId,
          );
    });
