import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement_model.dart';
import '../services/announcements_service.dart';
import 'access_providers.dart';

final announcementsServiceProvider = Provider<AnnouncementsService>(
  (ref) => AnnouncementsService(),
);

/// The announcements of the currently selected event. Re-fetches by itself when
/// the user switches events; empty while no event is selected.
///
/// `autoDispose` keeps the list fresh: `/announcements` is pushed on the root
/// navigator, so leaving the screen drops the last listener and disposes the
/// cached result, and re-entering refetches (mirrors [tipsProvider]). Swap for a
/// `StreamProvider` over `snapshots()` if announcements ever need to update while
/// on screen.
final announcementsProvider =
    FutureProvider.autoDispose<List<AnnouncementModel>>((ref) async {
      final eventId = ref.watch(selectedEventIdProvider);
      if (eventId == null) return const [];
      return ref.watch(announcementsServiceProvider).getAnnouncements(eventId);
    });
