import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/support_model.dart';
import '../services/support_service.dart';
import 'access_providers.dart';
import 'auth_providers.dart';

final supportServiceProvider = Provider<SupportService>(
  (ref) => SupportService(),
);

/// The signed-in user's support requests for the selected event, live.
///
/// Streamed rather than fetched: the whole point of this screen is that an
/// admin's reply arrives, and a list that only refreshed on open would tell a
/// user they are still waiting when they aren't.
///
/// `autoDispose`, like the community feed: `/support` is pushed on the root
/// navigator, so leaving the screen drops the listener rather than holding a
/// Firestore stream open for the rest of the session.
final supportRequestsProvider =
    StreamProvider.autoDispose<List<SupportRequest>>((ref) {
      final eventId = ref.watch(selectedEventIdProvider);
      final uid = ref.watch(currentUserProvider)?.uid;
      if (eventId == null || uid == null) return Stream.value(const []);
      return ref.watch(supportServiceProvider).watchMyRequests(eventId, uid);
    });

/// One request, live — null once it no longer exists (the panel may delete a
/// thread). The chat screen's header reads this, which is also how the user sees
/// their request being marked resolved while they have it open.
final supportRequestProvider = StreamProvider.autoDispose
    .family<SupportRequest?, String>((ref, requestId) {
      final eventId = ref.watch(selectedEventIdProvider);
      if (eventId == null) return Stream.value(null);
      return ref.watch(supportServiceProvider).watchRequest(eventId, requestId);
    });

/// A request's messages, oldest first — the order a conversation reads in.
final supportMessagesProvider = StreamProvider.autoDispose
    .family<List<SupportMessage>, String>((ref, requestId) {
      final eventId = ref.watch(selectedEventIdProvider);
      if (eventId == null) return Stream.value(const []);
      return ref
          .watch(supportServiceProvider)
          .watchMessages(eventId, requestId);
    });

/// How many of the user's requests are still waiting on the support team — the
/// count a badge on the Contact tile would show. Zero while nothing is loaded.
final supportAwaitingCountProvider = Provider.autoDispose<int>((ref) {
  final requests = ref.watch(supportRequestsProvider).valueOrNull ?? const [];
  return requests.where((r) => r.isAwaitingSupport).length;
});
