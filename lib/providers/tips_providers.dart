import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tips_model.dart';
import '../services/tips_service.dart';
import 'access_providers.dart';

final tipsServiceProvider = Provider<TipsService>((ref) => TipsService());

/// The "Important Tips" of the currently selected event. Re-fetches by itself
/// when the user switches events; empty while no event is selected.
///
/// `autoDispose` is what keeps the list fresh: `/tips` is pushed on the root
/// navigator, so leaving the screen drops the last listener and disposes the
/// cached result, and re-entering refetches. Without it the fetch would run
/// once per app launch and admin-panel edits would only show up after a
/// restart. Opening a single tip on top of the list does not refetch — the
/// list stays mounted underneath, which is the intent.
///
/// If tips ever need to update while the user is looking at them, swap this
/// for a `StreamProvider` over `snapshots()` instead of adding a manual
/// refresh: the initial load costs the same, and after that only changed
/// documents are billed as reads.
final tipsProvider = FutureProvider.autoDispose<List<TipModel>>((ref) async {
  final eventId = ref.watch(selectedEventIdProvider);
  if (eventId == null) return const [];
  return ref.watch(tipsServiceProvider).getTips(eventId);
});
