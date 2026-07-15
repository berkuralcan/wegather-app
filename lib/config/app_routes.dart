import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_widgets/auth_wrapper.dart';
import '../auth_widgets/login_screen.dart';
import '../auth_widgets/reset_password_screen.dart';
import '../legal/kvkk_screen.dart';
import '../legal/terms_and_conditions_screen.dart';
import '../layouts/main_scaffold.dart';
import '../screens/calendar_screen.dart';
import '../screens/modules_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/profile_tab_screen.dart';
import '../providers/auth_providers.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      redirect: (context, state) {
        final authState = ref.read(authStateProvider);
        final location = state.uri.toString();
        // Routes reachable without being logged in.
        const publicRoutes = {'/login', '/reset-password', '/terms', '/kvkk'};

        return authState.when(
          data: (user) {
            // If user is null (not logged in) and not on a public page, redirect to login
            if (user == null && !publicRoutes.contains(location)) {
              return '/login';
            }
            // If user is logged in and on login page, redirect to home
            if (user != null && location == '/login') {
              return '/';
            }
            return null; // No redirect needed
          },
          loading: () => null, // Let the loading state handle itself
          error: (_, __) => '/login',
        );
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
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/modules',
                  name: 'modules',
                  builder: (context, state) => const ModulesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  name: 'profileTab',
                  builder: (context, state) => const ProfileTabScreen(),
                ),
              ],
            ),
          ],
        ),
        // Full-screen routes pushed on top of the shell (no bottom bar).
        GoRoute(
          path: '/profile/:profileId',
          name: 'profile',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final profileId = state.pathParameters['profileId']!;
            return ProfileScreen(profileId: profileId);
          },
        ),
      ],
    );
  }
}
