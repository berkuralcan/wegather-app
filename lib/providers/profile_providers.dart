import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import 'auth_providers.dart';

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(),
);

/// The signed-in user's own `users/{uid}` document, refetched whenever the
/// signed-in user changes. Null while signed out (the router redirects then, so
/// screens only ever see this in the moment before it resolves).
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileServiceProvider).getProfile(user.uid);
});
