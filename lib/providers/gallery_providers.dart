import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gallery_media.dart';
import '../services/gallery_service.dart';
import 'access_providers.dart';

final galleryServiceProvider = Provider<GalleryService>(
  (ref) => GalleryService(),
);

/// The gallery of the currently selected event, newest first. Empty while no
/// event is selected.
///
/// `autoDispose` for the same reason the tips list uses it: `/gallery` is
/// pushed on the root navigator, so leaving the screen drops the last listener
/// and re-entering refetches — which matters more here than anywhere else,
/// since other attendees are adding to this collection while the app is open.
/// The upload flow invalidates this provider so a new photo appears at once
/// rather than after a trip out of the screen.
final galleryProvider = FutureProvider.autoDispose<List<GalleryMedia>>((
  ref,
) async {
  final eventId = ref.watch(selectedEventIdProvider);
  if (eventId == null) return const [];
  return ref.watch(galleryServiceProvider).getMedia(eventId);
});
