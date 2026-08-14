import '../auth_services.dart';
import '../models/access_model.dart';
import '../models/event_model.dart';
import '../repositories/access_repository.dart';

/// Answers the two questions the app asks at startup: *who is signed in* and
/// *which events may they open*. See the `wegather-access-model` skill.
class AccessService {
  final AccessRepository _accessRepository = AccessRepository();
  final AuthService _authService = AuthService();

  /// The signed-in account's `users/{uid}` document.
  ///
  /// Null when nobody is signed in, or when the account has no user document —
  /// an account that was created in the Auth console but never provisioned.
  /// Such a user simply has no accessible events.
  Future<AppUser?> getCurrentUserProfile() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;
    return _accessRepository.getUserProfile(currentUser.uid);
  }

  /// The events [user] may open in the app:
  ///   * `super_admin` -> every event on the platform,
  ///   * `admin`       -> every event of the companies they administer, plus
  ///                      any event they were granted individually,
  ///   * `user`        -> the events granted in `user_event_access`.
  ///
  /// Note this is deliberately *not* filtered by the event's active window
  /// ([EventModel.isActiveAt]) yet — see that method's note.
  Future<List<EventModel>> getAccessibleEvents(AppUser user) async {
    if (user.role == UserRole.superAdmin) {
      return _sorted(await _accessRepository.getAllEvents());
    }

    // Company-wide events for admins, individually granted events for everyone.
    // An admin can also be a participant of somebody else's event, so the two
    // sets are merged rather than treated as alternatives.
    final companyIds = user.role == UserRole.admin
        ? await _accessRepository.getAdminCompanyIds(user.id)
        : const <String>[];
    final grantedIds = (await _accessRepository.getEventAccessRows(
      user.id,
    )).map((row) => row.eventId).toList();

    final byId = <String, EventModel>{};
    for (final event in await _accessRepository.getEventsForCompanies(
      companyIds,
    )) {
      byId[event.id] = event;
    }
    for (final event in await _accessRepository.getEventsByIds(grantedIds)) {
      byId[event.id] = event;
    }
    return _sorted(byId.values.toList());
  }

  /// Soonest event first, then alphabetically — a stable order for the picker.
  List<EventModel> _sorted(List<EventModel> events) {
    events.sort((a, b) {
      final byDate = a.eventStartDate.compareTo(b.eventStartDate);
      return byDate != 0 ? byDate : a.title.compareTo(b.title);
    });
    return events;
  }
}
