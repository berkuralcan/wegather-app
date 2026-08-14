import '../models/activity_model.dart';
import '../models/event_model.dart';
import '../repositories/activities_repository.dart';

/// Business logic around an event's schedule: fetching the activities, and
/// turning them into the two things the calendar screen renders — the list of
/// days to pick from, and the activities of the picked day.
class ActivitiesService {
  /// `late` so the day helpers below stay usable (and testable) without a
  /// Firebase app: the repository reaches for `FirebaseFirestore.instance` the
  /// moment it is constructed.
  late final ActivitiesRepository _activitiesRepository =
      ActivitiesRepository();

  /// Every activity of an event, earliest first.
  ///
  /// Ties are broken by title so the order is stable across fetches — two
  /// activities starting at the same time would otherwise come back in
  /// whatever order Firestore returned them in.
  Future<List<ActivityModel>> getActivities(String eventId) async {
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }
    final activities = await _activitiesRepository.getActivities(eventId);
    activities.sort((a, b) {
      final byStart = a.startDateTime.compareTo(b.startDateTime);
      return byStart != 0 ? byStart : a.title.compareTo(b.title);
    });
    return activities;
  }

  /// A single activity, or null if it doesn't exist.
  Future<ActivityModel?> getActivity(String eventId, String activityId) {
    if (eventId.isEmpty || activityId.isEmpty) {
      throw ArgumentError('Event ID and activity ID cannot be empty');
    }
    return _activitiesRepository.getActivity(eventId, activityId);
  }

  /// The event's whole roster, by name.
  ///
  /// Ties are broken by id so the order is stable across fetches, the same way
  /// [getActivities] breaks equal start times by title.
  Future<List<ParticipantModel>> getParticipants(String eventId) async {
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }
    final participants = await _activitiesRepository.getParticipants(eventId);
    participants.sort((a, b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return byName != 0 ? byName : a.id.compareTo(b.id);
    });
    return participants;
  }

  /// The activities [participantId] is assigned to, in the order they were
  /// given — read off the snapshots the activities already embed, so this
  /// costs no extra fetch. Empty for a participant with no id, which no
  /// snapshot can be matched against.
  List<ActivityModel> activitiesOf(
    List<ActivityModel> activities,
    String participantId,
  ) {
    if (participantId.isEmpty) return const [];
    return activities
        .where((a) => a.participants.any((p) => p.id == participantId))
        .toList();
  }

  /// The days the date picker offers, in order.
  ///
  /// The event's own start/end range is the backbone, so the picker shows every
  /// day of the event even before activities have been scheduled on it. Days
  /// touched by an activity are merged in on top: an activity scheduled outside
  /// the advertised range (or on an event whose dates are unset) stays
  /// reachable instead of disappearing from the schedule.
  List<DateTime> scheduleDays(
    List<ActivityModel> activities, {
    EventModel? event,
  }) {
    final days = <DateTime>{};
    if (event != null) {
      days.addAll(daysBetween(event.eventStartDate, event.eventEndDate));
    }
    for (final activity in activities) {
      days.addAll(activity.days);
    }
    final ordered = days.toList()..sort();
    return ordered;
  }

  /// The activities to show for [day] — including multi-day ones that merely
  /// run through it, which is why this is a filter rather than a group-by.
  List<ActivityModel> activitiesOn(
    List<ActivityModel> activities,
    DateTime day,
  ) => activities.where((activity) => activity.touchesDay(day)).toList();
}
