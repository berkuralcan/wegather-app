import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/gallery_media.dart';
import 'storage_service.dart';

/// Whether a picked file is a photo or a video.
///
/// The platform's own answer comes first, since it knows what the user actually
/// picked; iOS often reports no `mimeType` at all, and the extension answers the
/// same question.
GalleryMediaType mediaTypeOf(XFile file) {
  final mimeType = file.mimeType;
  if (mimeType != null && mimeType.startsWith('video/')) {
    return GalleryMediaType.video;
  }
  if (mimeType != null && mimeType.startsWith('image/')) {
    return GalleryMediaType.photo;
  }
  return GalleryMediaType.inferFrom(file.path);
}

/// What a finished upload leaves behind in Storage: the file's download URL and,
/// for a video, its poster frame's.
class UploadedMedia {
  final String url;

  /// Set for videos only, and null even then if the device couldn't produce a
  /// frame.
  final String? thumbUrl;

  const UploadedMedia({required this.url, this.thumbUrl});
}

/// Puts a photo or video the user picked into Storage under the event's
/// `userUploads` prefix.
///
/// This is the half of an upload that has nothing to do with what the media is
/// *for*: the content type it must be stored under, and the poster frame a video
/// needs. Both the gallery and a community post upload the same way and differ
/// only in what they record afterwards, so the pipeline lives here and each
/// feature's service keeps its own bookkeeping.
class MediaUploadService {
  final StorageService _storageService = StorageService();

  /// The longest edge of a generated video poster frame. Comfortably sharper
  /// than the ~95pt tile it is drawn in on a 3x screen, and a few tens of KB.
  static const int _thumbnailMaxWidth = 512;

  /// Uploads [file], plus a poster frame when it is a video.
  ///
  /// Failing to generate a poster frame is not fatal: the caller stores a null
  /// [UploadedMedia.thumbUrl] and whatever draws the media falls back to a play
  /// badge on an empty block.
  Future<UploadedMedia> upload({
    required String companyId,
    required String eventId,
    required XFile file,
    required GalleryMediaType type,
  }) async {
    if (companyId.isEmpty || eventId.isEmpty) {
      throw ArgumentError('Company ID and event ID cannot be empty');
    }

    final url = await _storageService.uploadGalleryFile(
      companyId: companyId,
      eventId: eventId,
      file: File(file.path),
      contentType: contentTypeFor(file, type),
    );

    final thumbUrl = type == GalleryMediaType.video
        ? await _uploadPosterFrame(
            companyId: companyId,
            eventId: eventId,
            videoPath: file.path,
          )
        : null;

    return UploadedMedia(url: url, thumbUrl: thumbUrl);
  }

  /// The content type to store the file under.
  ///
  /// Never null, and never guessed loosely: the storage rules only accept an
  /// upload whose content type says `image/…` or `video/…`, which is what stops
  /// the userUploads prefix from being used as free file hosting. iOS often
  /// hands over an [XFile] with no `mimeType`, so the extension is the fallback,
  /// and the kind of media the user picked is the last resort.
  String contentTypeFor(XFile file, GalleryMediaType type) {
    final mimeType = file.mimeType;
    if (mimeType != null && mimeType.isNotEmpty) return mimeType;

    const byExtension = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'heif': 'image/heif',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'm4v': 'video/x-m4v',
      '3gp': 'video/3gpp',
      'webm': 'video/webm',
    };
    final extension = file.path.split('.').last.toLowerCase();
    return byExtension[extension] ??
        (type == GalleryMediaType.video ? 'video/mp4' : 'image/jpeg');
  }

  /// Generates a video's first frame and uploads it next to the media, or
  /// returns null if the device couldn't produce one.
  ///
  /// It is generated here, from the local file, because the alternative is every
  /// device downloading and decoding every clip just to draw a grid of tiles.
  Future<String?> _uploadPosterFrame({
    required String companyId,
    required String eventId,
    required String videoPath,
  }) async {
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: _thumbnailMaxWidth,
        quality: 75,
      );
      if (bytes == null || bytes.isEmpty) return null;

      final name = videoPath.split('/').last.split('.').first;
      return await _storageService.uploadGalleryBytes(
        companyId: companyId,
        eventId: eventId,
        bytes: bytes,
        fileName: '$name-thumb.jpg',
        contentType: 'image/jpeg',
      );
    } catch (_) {
      // A missing poster frame costs a nice-looking tile, not the upload.
      return null;
    }
  }
}
