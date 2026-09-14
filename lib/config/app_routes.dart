import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_widgets/auth_wrapper.dart';
import '../auth_widgets/login_screen.dart';
import '../auth_widgets/reset_password_screen.dart';
import '../legal/kvkk_screen.dart';
import '../legal/terms_and_conditions_screen.dart';
import '../layouts/main_scaffold.dart';
import '../models/community_model.dart';
import '../models/support_model.dart';
import '../screens/activity_detail_screen.dart';
import '../screens/announcements_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/community_screen.dart';
import '../screens/create_post.dart';
import '../screens/documents_screen.dart';
import '../screens/event_selection_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/home_screen.dart';
import '../screens/participant_detail_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/my_profile_screen.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/profile_information_screen.dart';
import '../screens/profile_qr_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/profile_section_placeholders.dart';
import '../screens/support_chat_screen.dart';
import '../screens/support_requests_screen.dart';
import '../screens/tips_screen.dart';
import '../screens/flight_reservation_screen.dart';
import '../screens/transportation_screen.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';

/// The app's router. Read it from [routerProvider] rather than constructing it,
/// so it is built once and can refresh itself when auth or event selection
/// changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return AppRouter.createRouter(ref, refreshListenable: refresh);
});

/// Bridges Riverpod to GoRouter: any change to the signed-in user or to the
/// selected event re-runs [AppRouter]'s redirect. Without this the app would
/// sit on a stale screen after login, logout, or picking an event.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(selectedEventProvider, (_, __) => notifyListeners());
  }
}

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter createRouter(Ref ref, {Listenable? refreshListenable}) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: refreshListenable,
      redirect: (context, state) {
        final location = state.uri.path;
        // Routes reachable without being logged in.
        const publicRoutes = {'/login', '/reset-password', '/terms', '/kvkk'};

        final authState = ref.read(authStateProvider);
        if (authState.isLoading) return null; // Let the loader show.
        if (authState.hasError) return '/login';

        final user = authState.valueOrNull;
        if (user == null) {
          return publicRoutes.contains(location) ? null : '/login';
        }
        if (location == '/login') return '/';
        // Terms/KVKK stay reachable while logged in.
        if (publicRoutes.contains(location)) return null;

        // Logged in: every screen below is scoped to an event, so one has to be
        // selected first. `null` once resolved means "pick one" — either the
        // user has several events or none at all (the picker handles both).
        final selectedEvent = ref.read(selectedEventProvider);
        if (selectedEvent.isLoading) return null; // Screens show a loader.
        if (selectedEvent.valueOrNull == null && location != '/events') {
          return '/events';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          name: 'resetPassword',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/terms',
          name: 'terms',
          builder: (context, state) => const TermsAndConditionsScreen(),
        ),
        GoRoute(
          path: '/kvkk',
          name: 'kvkk',
          builder: (context, state) => const KvkkScreen(),
        ),
        // Event picker — shown before the app shell, so it has no bottom bar.
        GoRoute(
          path: '/events',
          name: 'events',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const EventSelectionScreen(),
        ),
        // Main app shell with a persistent bottom navigation bar.
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScaffold(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  name: 'home',
                  builder: (context, state) => const AuthWrapper(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/calendar',
                  name: 'calendar',
                  builder: (context, state) => const CalendarScreen(),
                  routes: [
                    // Nested, so the detail page is pushed inside the calendar
                    // branch: the bottom bar stays and back returns here.
                    GoRoute(
                      path: 'activity/:activityId',
                      name: 'activity',
                      builder: (context, state) => ActivityDetailScreen(
                        activityId: state.pathParameters['activityId']!,
                      ),
                      routes: [
                        // Nested again: back from a participant returns to the
                        // activity they were opened from.
                        GoRoute(
                          path: 'participant/:participantId',
                          name: 'participant',
                          builder: (context, state) => ParticipantDetailScreen(
                            activityId: state.pathParameters['activityId']!,
                            participantId:
                                state.pathParameters['participantId']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/modules',
                  name: 'modules',
                  // The module grid: the app's old home screen, now reachable
                  // from the third tab only.
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  name: 'profileTab',
                  builder: (context, state) => const MyProfileScreen(),
                  // Each section of your own profile is nested under it, so
                  // its path says where it belongs and back returns to the
                  // profile. They open on the root navigator, though — a
                  // section is a page you went into, so it covers the bottom
                  // bar the way the documents and tips screens do.
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: 'profileEdit',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const ProfileEditScreen(),
                    ),
                    GoRoute(
                      path: 'information',
                      name: 'profileInformation',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileInformationScreen(),
                    ),
                    GoRoute(
                      path: 'qr',
                      name: 'profileQr',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const ProfileQrScreen(),
                    ),
                    // The three sections that are named but not built yet.
                    GoRoute(
                      path: 'accommodation',
                      name: 'profileAccommodation',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileAccommodationScreen(),
                    ),
                    GoRoute(
                      path: 'transportation',
                      name: 'profileTransportation',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileTransportationInfoScreen(),
                    ),
                    GoRoute(
                      path: 'flights',
                      name: 'profileFlights',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileFlightsInfoScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // Full-screen routes pushed on top of the shell (no bottom bar).
        GoRoute(
          path: '/tips',
          name: 'tips',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const TipsScreen(),
        ),
        GoRoute(
          path: '/announcements',
          name: 'announcements',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AnnouncementsScreen(),
        ),
        GoRoute(
          path: '/community',
          name: 'community',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const CommunityScreen(),
        ),
        // The composer, over the feed rather than inside it: it is a task the
        // user either finishes or abandons, so it covers the bottom bar too.
        GoRoute(
          path: '/community/create',
          name: 'createPost',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/community/post/:postId',
          name: 'post',
          parentNavigatorKey: _rootNavigatorKey,
          // The feed passes the post it already has as `extra`, so the screen
          // paints immediately and its own stream only refreshes it. Reached
          // without one — a deep link — it loads the post by id instead.
          builder: (context, state) => PostDetailScreen(
            postId: state.pathParameters['postId']!,
            initialPost: state.extra is CommunityPost
                ? state.extra as CommunityPost
                : null,
          ),
        ),
        GoRoute(
          path: '/transportation',
          name: 'transportation',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const TransportationScreen(),
        ),
        // External travel — reaching the event city and going home again. A
        // separate screen from /transportation because it is a request the
        // organisers fulfil, not a seat the participant takes.
        GoRoute(
          path: '/flights',
          name: 'flights',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const FlightReservationScreen(),
        ),
        GoRoute(
          path: '/gallery',
          name: 'gallery',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const GalleryScreen(),
        ),
        GoRoute(
          path: '/documents',
          name: 'documents',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const DocumentsScreen(),
        ),
        // Support: the participant's own requests, and one conversation. The
        // chat is nested so back from a thread returns to the list it was
        // opened from.
        GoRoute(
          path: '/support',
          name: 'support',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SupportRequestsScreen(),
          routes: [
            GoRoute(
              path: 'request/:requestId',
              name: 'supportRequest',
              parentNavigatorKey: _rootNavigatorKey,
              // The list passes the request it already has as `extra`, so the
              // thread paints its header immediately and its own stream only
              // refreshes it. Opened without one — straight after creating a
              // request — it loads by id instead.
              builder: (context, state) => SupportChatScreen(
                requestId: state.pathParameters['requestId']!,
                initialRequest: state.extra is SupportRequest
                    ? state.extra as SupportRequest
                    : null,
              ),
            ),
          ],
        ),
        // Somebody else's profile, reached by tapping whoever wrote a post.
        // Its own path rather than a child of /profile, which is the tab that
        // is always yours — and the two views are different screens, so the
        // builder sends you to your own when the id turns out to be yours
        // (tapping your own avatar in the feed, say).
        GoRoute(
          path: '/user/:profileId',
          name: 'profile',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final profileId = state.pathParameters['profileId']!;
            final uid = ref.read(currentUserProvider)?.uid;
            if (profileId == uid) return const MyProfileScreen();
            return ProfileScreen(profileId: profileId);
          },
        ),
      ],
    );
  }
}
