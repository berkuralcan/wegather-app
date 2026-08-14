import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/activity_model.dart' show startOfDay;
import '../models/gallery_media.dart';
import '../repositories/gallery_repository.dart';
import 'media_upload_service.dart';

/// A day as the gallery writes it: `DD.MM.YYYY`. Deliberately numeric and
/// locale-independent — it is the same heading in every language the app runs
/// in, and the section headings have to line up down the page.
String formatGalleryDay(DateTime day) => DateFormat('dd.MM.yyyy').format(day);

/// Business logic around an event's user-contributed gallery: reading it,
/// grouping it into days, adding to it, and reporting a piece of it.
class GalleryService {
  final GalleryRepository _galleryRepository = GalleryRepository();
  final MediaUploadService _uploader = MediaUploadService();

  /// Every piece of media in an event's gallery, newest first.
  Future<List<GalleryMedia>> getMedia(String eventId) {
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }
    return _galleryRepository.getMedia(eventId);
  }

  /// Splits [media] into one section per calendar day, newest day first.
  ///
  /// The list arrives ordered by `uploadedAt` descending, so days come out in
  /// order simply by walking it. Media whose timestamp hasn't resolved yet —
  /// the brief window after a local write, before the server clock lands — is
  /// grouped under today, which is where it will end up anyway.
  List<GalleryDaySection> groupByDay(List<GalleryMedia> media) {
    final sections = <GalleryDaySection>[];
    final today = startOfDay(DateTime.now());

    for (final item in media) {
      final day = item.uploadedAt == null
          ? today
          : startOfDay(item.uploadedAt!);
      if (sections.isNotEmpty && sections.last.day == day) {
        sections.last.media.add(item);
      } else {
        sections.add(GalleryDaySection(day: day, media: [item]));
      }
    }
    return sections;
  }

  /// Only the media of one kind, in the order it was given.
  List<GalleryMedia> ofType(List<GalleryMedia> media, GalleryMediaType type) =>
      media.where((item) => item.type == type).toList(growable: false);

  /// Uploads a picked file to Storage and records it in the event's gallery.
  ///
  /// [MediaUploadService] is what puts the file (and a video's poster frame)
  /// there; this only records what came back.
  Future<GalleryMedia> upload({
    required String companyId,
    required String eventId,
    required String userId,
    required XFile file,
    required GalleryMediaType type,
  }) async {
    if (companyId.isEmpty || eventId.isEmpty || userId.isEmpty) {
      throw ArgumentError('Company ID, event ID and user ID cannot be empty');
    }

    final uploaded = await _uploader.upload(
      companyId: companyId,
      eventId: eventId,
      file: file,
      type: type,
    );

    final media = GalleryMedia(
      id: '',
      mediaUrl: uploaded.url,
      thumbUrl: uploaded.thumbUrl,
      uploadedBy: userId,
      type: type,
      uploadedAt: null,
      isReported: false,
    );

    final id = await _galleryRepository.addMedia(eventId, media);
    return GalleryMedia(
      id: id,
      mediaUrl: media.mediaUrl,
      thumbUrl: media.thumbUrl,
      uploadedBy: media.uploadedBy,
      type: media.type,
      // The server's value isn't read back; the caller refreshes the gallery,
      // and until then the item groups under today either way.
      uploadedAt: DateTime.now(),
      isReported: false,
    );
  }

  /// Flags a piece of media for the admin panel to moderate.
  Future<void> report({
    required String eventId,
    required String mediaId,
    required String userId,
    String? reason,
  }) {
    if (eventId.isEmpty || mediaId.isEmpty || userId.isEmpty) {
      throw ArgumentError('Event ID, media ID and user ID cannot be empty');
    }
    return _galleryRepository.reportMedia(
      eventId,
      mediaId,
      reportedBy: userId,
      reason: reason,
    );
  }
}
