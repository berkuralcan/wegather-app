import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which event a user last opened, so they don't have to pick it
/// again on every launch (mirroring the admin panel's persisted
/// `applicationStore`).
///
/// Only the event *id* is stored, never the event itself: on the next launch
/// the id is resolved against the events the user currently has access to, so a
/// revoked grant can't leave a stale event open.
class SelectedEventStorage {
  /// Keyed per account so switching users can't inherit a selection.
  static String _key(String userId) => 'selected_event_id:$userId';

  Future<String?> readEventId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(userId));
  }

  Future<void> writeEventId(String userId, String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), eventId);
  }

  Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}
