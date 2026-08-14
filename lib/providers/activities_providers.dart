import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_model.dart';
import '../services/activities_service.dart';
import 'access_providers.dart';

final activitiesServiceProvider = Provider<ActivitiesService>(
  (ref) => ActivitiesService(),
);

/// The schedule of the currently selected event. Re-fetches by itself when the
/// user switches events; empty while no event is selected.
///
/// `autoDispose` keeps it fresh the same way `tipsProvider` does: the cached
/// result is dropped once the calendar screen has no listeners left, so an
/// admin-panel edit shows up on the next visit rather than after a restart.
///
/// If the schedule ever needs to update while the user is looking at it, swap
/// this for a `StreamProvider` over `snapshots()` instead of adding a manual
/// refresh — the initial load costs the same, and after that only changed
/// documents are billed as reads.
final activitiesProvider = FutureProvider.autoDispose<List<ActivityModel>>((
  ref,
) async {
  final eventId = ref.watch(selectedEventIdProvider);
  if (eventId == null) return const [];
  return ref.watch(activitiesServiceProvider).getActivities(eventId);
});

/// A single activity of the schedule, by id — resolved out of the already
/// fetched [activitiesProvider] rather than re-read from Firestore, so opening
/// an activity from the calendar costs nothing. The value is null once the
/// schedule has loaded and holds no activity with that id (deleted meanwhile,
/// or a stale link).
final activityProvider = Provider.autoDispose
    .family<AsyncValue<ActivityModel?>, String>((ref, activityId) {
      return ref
          .watch(activitiesProvider)
          .whenData(
            (activities) => activities.cast<ActivityModel?>().firstWhere(
              (a) => a!.id == activityId,
              orElse: () => null,
            ),
          );
    });

/// One person of an activity's roster, by id — read out of the snapshot the
/// activity already embeds, so opening a participant costs no extra fetch. The
/// value is null once the schedule has loaded and the activity is gone, or holds
/// no participant with that id.
final participantProvider = Provider.autoDispose
    .family<
      AsyncValue<ParticipantModel?>,
      ({String activityId, String participantId})
    >((ref, key) {
      return ref
          .watch(activityProvider(key.activityId))
          .whenData(
            (activity) =>
                activity?.participants.cast<ParticipantModel?>().firstWhere(
                  (p) => p!.id == key.participantId,
                  orElse: () => null,
                ),
          );
    });

/// The selected event's whole roster, by name. Unlike [participantProvider]
/// this is a real fetch: the roster is a collection of its own, and an activity
/// only ever embeds the slice of it that is assigned to that activity.
///
/// `autoDispose` for the same reason as [activitiesProvider]: the cached roster
/// is dropped once no page is showing it, so a panel edit lands on the next
/// visit. Empty while no event is selected.
final eventParticipantsProvider =
    FutureProvider.autoDispose<List<ParticipantModel>>((ref) async {
      final eventId = ref.watch(selectedEventIdProvider);
      if (eventId == null) return const [];
      return ref.watch(activitiesServiceProvider).getParticipants(eventId);
    });

/// The activities a participant takes part in, by participant id — filtered out
/// of the already fetched [activitiesProvider] rather than queried, so it costs
/// no extra read: every activity carries a snapshot of its roster, which is
/// exactly what "is this person in it?" is asked of.
final participantActivitiesProvider = Provider.autoDispose
    .family<AsyncValue<List<ActivityModel>>, String>((ref, participantId) {
      final service = ref.watch(activitiesServiceProvider);
      return ref
          .watch(activitiesProvider)
          .whenData(
            (activities) => service.activitiesOf(activities, participantId),
          );
    });

/// The days the calendar's date picker offers, earliest first — the event's own
/// range merged with the days its activities fall on. Empty until the schedule
/// has loaded.
final scheduleDaysProvider = Provider.autoDispose<List<DateTime>>((ref) {
  final activities = ref.watch(activitiesProvider).valueOrNull ?? const [];
  final event = ref.watch(selectedEventProvider).valueOrNull;
  return ref
      .watch(activitiesServiceProvider)
      .scheduleDays(activities, event: event);
});
