import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/access_model.dart';
import '../models/event_model.dart';
import '../services/access_service.dart';
import '../services/selected_event_storage.dart';
import 'auth_providers.dart';

/// The access layer as Riverpod state. The chain is:
///
///   authState -> appUser -> accessibleEvents -> selectedEvent
///
/// Everything the app fetches from Firestore hangs off the selected event, so
/// [selectedEventIdProvider] is the single place feature providers should read
/// "which event am I in?" from. Signing out invalidates the whole chain.

final accessServiceProvider = Provider<AccessService>((ref) => AccessService());

final selectedEventStorageProvider = Provider<SelectedEventStorage>(
  (ref) => SelectedEventStorage(),
);

/// The signed-in account's `users/{uid}` document (null when signed out, or
/// when the account has no user document yet).
final appUserProvider = FutureProvider<AppUser?>((ref) async {
  final authUser = await ref.watch(authStateProvider.future);
  if (authUser == null) return null;
  return ref.watch(accessServiceProvider).getCurrentUserProfile();
});

/// Every event the signed-in user may open, per the access model.
final accessibleEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final appUser = await ref.watch(appUserProvider.future);
  if (appUser == null) return const [];
  return ref.watch(accessServiceProvider).getAccessibleEvents(appUser);
});

/// The event the user is currently in, or null when one still has to be picked.
///
/// Resolution order on startup: the remembered event (if the user still has
/// access to it), otherwise the only accessible event if there is exactly one,
/// otherwise null — which sends the router to the event picker.
class SelectedEventController extends AsyncNotifier<EventModel?> {
  @override
  Future<EventModel?> build() async {
    final appUser = await ref.watch(appUserProvider.future);
    if (appUser == null) return null;

    final events = await ref.watch(accessibleEventsProvider.future);
    if (events.isEmpty) return null;

    final storedId = await ref
        .read(selectedEventStorageProvider)
        .readEventId(appUser.id);
    for (final event in events) {
      if (event.id == storedId) return event;
    }

    // A single-event user never sees the picker.
    if (events.length == 1) {
      await _remember(appUser.id, events.first.id);
      return events.first;
    }
    return null;
  }

  /// Enter [event] — called from the event picker.
  Future<void> select(EventModel event) async {
    final appUser = ref.read(appUserProvider).valueOrNull;
    if (appUser != null) await _remember(appUser.id, event.id);
    state = AsyncData(event);
  }

  /// Leave the current event and forget it (e.g. to switch events).
  Future<void> clear() async {
    final appUser = ref.read(appUserProvider).valueOrNull;
    if (appUser != null) {
      await ref.read(selectedEventStorageProvider).clear(appUser.id);
    }
    state = const AsyncData(null);
  }

  Future<void> _remember(String userId, String eventId) =>
      ref.read(selectedEventStorageProvider).writeEventId(userId, eventId);
}

final selectedEventProvider =
    AsyncNotifierProvider<SelectedEventController, EventModel?>(
      SelectedEventController.new,
    );

/// The current event's id — what feature queries scope themselves to. Null
/// while the selection is still resolving or when no event is selected.
final selectedEventIdProvider = Provider<String?>(
  (ref) => ref.watch(selectedEventProvider).valueOrNull?.id,
);
