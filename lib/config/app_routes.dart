import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth_widgets/auth_wrapper.dart';
import '../auth_widgets/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/auth_providers.dart';

class AppRouter {
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final authState = ref.read(authStateProvider);
        
        return authState.when(
          data: (user) {
            // If user is null (not logged in) and not on login page, redirect to login
            if (user == null && state.uri.toString() != '/login') {
              return '/login';
            }
            // If user is logged in and on login page, redirect to home
            if (user != null && state.uri.toString() == '/login') {
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
          path: '/',
          name: 'home',
          builder: (context, state) => const AuthWrapper(),
        ),
        GoRoute(
          path: '/profile/:profileId',
          name: 'profile',
          builder: (context, state) {
            final profileId = state.pathParameters['profileId']!;
            return ProfileScreen(profileId: profileId);
          },
        ),
      ],
    );
  }
}