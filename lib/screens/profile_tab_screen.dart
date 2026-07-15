import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegather_app/providers/auth_providers.dart';
import 'package:wegather_app/screens/profile_screen.dart';

/// Wraps [ProfileScreen] for the bottom-nav "Profile" tab, resolving the
/// currently authenticated user's id so the tab always shows the user's own
/// profile.
class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ProfileScreen(profileId: user.uid);
  }
}
