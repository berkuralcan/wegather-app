import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_services.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Stream provider to listen to auth state changes

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.read(authServiceProvider);
  return authService.authStateChanges.cast<User?>();
});

// Get the current user

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) => user,
    error: (_, __) => null,
    loading: () => null,
  );
});