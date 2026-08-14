import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegather_app/providers/access_providers.dart';
import 'package:wegather_app/providers/auth_providers.dart';
import 'package:wegather_app/screens/landing_screen.dart';

/// Gate in front of the app's home tab: the user must be signed in *and* be
/// inside an event before the landing screen means anything.
///
/// Both "signed out" and "no event selected" are handled by the router's
/// redirect; this only covers the moment before either has resolved, so the
/// user sees a loader instead of an event-less landing screen.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final selectedEvent = ref.watch(selectedEventProvider);

    if (authState.hasError || selectedEvent.hasError) {
      return const Scaffold(body: Center(child: Text("Error")));
    }
    if (authState.isLoading || selectedEvent.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const LandingScreen();
  }
}
