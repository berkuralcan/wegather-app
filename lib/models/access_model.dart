import 'package:cloud_firestore/cloud_firestore.dart';

/// The WeGather access model, ported from the admin panel's `types/access.ts`.
/// See the `wegather-access-model` skill for the full design (roles,
/// collections, composite ids, rules, flows).
///
/// In short:
///   * a user's platform tier lives on `users/{uid}.role`,
///   * admins are attached to *companies* via `user_company_roles`,
///   * app users are granted single *events* via `user_event_access`,
///   * both junctions are keyed by a deterministic composite id so membership
///     is a direct document lookup (in code and in security rules).

/// Firestore collection names, in one place to avoid typos.
class Collections {
  const Collections._();

  static const String companies = 'companies';
  static const String events = 'events';
  static const String users = 'users';
  static const String userCompanyRoles = 'user_company_roles';
  static const String userEventAccess = 'user_event_access';

  /// Subcollection of an event: `events/{eventId}/tips/{tipId}`.
  static const String tips = 'tips';

  /// Subcollection of an event: `events/{eventId}/announcements/{id}`.
  static const String announcements = 'announcements';

  /// Subcollection of an event: `events/{eventId}/activities/{activityId}`.
  static const String activities = 'activities';

  /// Subcollection of an event: `events/{eventId}/participants/{id}` — the
  /// roster. Activities embed snapshots of it, so the schedule never reads it.
  static const String participants = 'participants';

  /// Subcollection of an event: `events/{eventId}/gallery/{mediaId}` — the
  /// photos and videos users contribute. The one collection the app itself
  /// writes to.
  static const String gallery = 'gallery';

  /// Subcollection of an event: `events/{eventId}/documents/{id}` — files
  /// managers share for attendees to open.
  static const String documents = 'documents';

  /// Subcollection of an event: `events/{eventId}/community/{postId}` — the
  /// Instagram-like feed. Along with the gallery, one of the collections the
  /// app itself writes to (posts, likes, comments).
  static const String community = 'community';

  /// Subcollection of a post: `.../community/{postId}/likes/{uid}`. Keyed by the
  /// liker's uid so a like is idempotent.
  static const String likes = 'likes';

  /// Subcollection of a post: `.../community/{postId}/comments/{commentId}`.
  static const String comments = 'comments';

  /// Subcollection of an event: `events/{eventId}/destinations/{id}` — the
  /// places transfers run between (hotels, venues, airports).
  static const String destinations = 'destinations';

  /// Subcollection of an event:
  /// `events/{eventId}/internalTransportations/{id}` — a scheduled transfer
  /// between two destinations, with a seat capacity.
  static const String internalTransportations = 'internalTransportations';

  /// Subcollection of a transfer: `.../internalTransportations/{id}/bookings/{uid}`.
  /// Keyed by the booking user's uid so a seat is idempotent — the same
  /// convention [likes] uses. One of the collections the app itself writes to.
  static const String bookings = 'bookings';

  /// Subcollection of an event: `events/{eventId}/travelDestinations/{id}` —
  /// the origin cities and airports EXTERNAL flights run between. Separate from
  /// [destinations] (hotels and venues in the event city) so neither list
  /// pollutes the other's picker.
  static const String travelDestinations = 'travelDestinations';

  /// Subcollection of an event:
  /// `events/{eventId}/externalTransportations/{id}` — a flight admins publish
  /// for participants to request.
  static const String externalTransportations = 'externalTransportations';

  /// Subcollection of a flight: `.../externalTransportations/{id}/seats/{uid}`.
  /// The countable mirror of who is on a capacity-limited flight — it exists
  /// because the request document itself is not broadly readable. One of the
  /// collections the app itself writes to.
  static const String seats = 'seats';

  /// Subcollection of an event:
  /// `events/{eventId}/externalTransportationBookings/{uid}` — one travel
  /// request per participant, keyed by their uid. The app writes the request;
  /// the panel writes its status and each leg's ticket.
  static const String externalTransportationBookings =
      'externalTransportationBookings';

  /// Subcollection of an event: `events/{eventId}/supportRequests/{id}` — a
  /// participant's conversation with the event's managers. Unlike the feed and
  /// the gallery, a request is readable only by its author and the managers,
  /// so every query the app makes here filters on `requesterId`.
  static const String supportRequests = 'supportRequests';

  /// Subcollection of a request: `.../supportRequests/{id}/messages/{msgId}` —
  /// the conversation itself. One of the collections the app writes to.
  static const String supportMessages = 'messages';
}

/// A user's platform tier, stored on `users/{uid}.role`.
enum UserRole {
  superAdmin('super_admin'),
  admin('admin'),
  user('user');

  const UserRole(this.jsonValue);

  final String jsonValue;

  /// Unknown/missing values fall back to the least privileged tier.
  static UserRole fromJson(String? value) => UserRole.values.firstWhere(
    (r) => r.jsonValue == value,
    orElse: () => UserRole.user,
  );
}

/// Access granted to an app user for a single event.
enum EventAccessLevel {
  full('full'),
  limited('limited');

  const EventAccessLevel(this.jsonValue);

  final String jsonValue;

  static EventAccessLevel fromJson(String? value) =>
      EventAccessLevel.values.firstWhere(
        (l) => l.jsonValue == value,
        orElse: () => EventAccessLevel.limited,
      );
}

/// Deterministic id for a `user_company_roles` document.
String companyRoleId(String userId, String companyId) => '${userId}_$companyId';

/// Deterministic id for a `user_event_access` document.
String eventAccessId(String userId, String eventId) => '${userId}_$eventId';

/// `users/{uid}` — keyed by the Firebase Auth uid.
///
/// This is the *authorization* view of a user (which tier they are). The
/// richer, profile-page view lives in [ProfileModel] over the same document.
class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.createdAt,
    this.lastLogin,
  });

  factory AppUser.fromJson(String id, Map<String, dynamic> json) {
    return AppUser(
      id: id,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: UserRole.fromJson(json['role'] as String?),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (json['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  /// Whether this user sees events company-wide rather than one-by-one.
  bool get isPlatformStaff =>
      role == UserRole.superAdmin || role == UserRole.admin;
}

/// `user_event_access/{userId}_{eventId}` — app user ⇄ event.
class UserEventAccess {
  final String userId;
  final String eventId;

  /// Denormalized from the event so rows can be queried per company.
  final String companyId;
  final EventAccessLevel accessLevel;
  final DateTime? createdAt;

  const UserEventAccess({
    required this.userId,
    required this.eventId,
    required this.companyId,
    required this.accessLevel,
    this.createdAt,
  });

  factory UserEventAccess.fromJson(Map<String, dynamic> json) {
    return UserEventAccess(
      userId: json['userId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      accessLevel: EventAccessLevel.fromJson(json['accessLevel'] as String?),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
