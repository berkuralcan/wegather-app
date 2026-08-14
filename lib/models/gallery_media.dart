import 'package:cloud_firestore/cloud_firestore.dart';

/// Whether a piece of gallery media is a still image or a video.
///
/// Stored on the document so the grid knows what a tile is without fetching it,
/// but every read falls back to [inferFrom] — a document written by an older
/// build (or by hand) may not carry the field, and a URL still gives it away.
enum GalleryMediaType {
  photo('photo'),
  video('video');

  const GalleryMediaType(this.jsonValue);

  final String jsonValue;

  /// File extensions that mean "video". Anything else is treated as a photo,
  /// which is the safer default: a photo tile renders a video's poster frame
  /// badly, but a video tile on a photo would offer playback that can't work.
  static const _videoExtensions = {
    'mp4',
    'mov',
    'm4v',
    '3gp',
    'avi',
    'mkv',
    'webm',
    'hevc',
  };

  /// The type [value] names, or null when it names nothing known.
  static GalleryMediaType? fromJson(String? value) {
    for (final type in GalleryMediaType.values) {
      if (type.jsonValue == value) return type;
    }
    return null;
  }

  /// Guesses the type from a file path or download URL by its extension.
  ///
  /// Firebase download URLs put the path in a query parameter and append a
  /// token, so the extension is looked for in the whole string rather than at
  /// its end: `.../o/abc%2Fclip.mp4?alt=media&token=...`.
  static GalleryMediaType inferFrom(String pathOrUrl) {
    final lower = pathOrUrl.toLowerCase();
    for (final extension in _videoExtensions) {
      if (lower.contains('.$extension')) return GalleryMediaType.video;
    }
    return GalleryMediaType.photo;
  }
}

/// One photo or video a user contributed to an event's gallery.
///
/// Gallery media lives in a subcollection of its event —
/// `events/{eventId}/gallery/{mediaId}` — and inherits its access for reads.
/// Unlike every other collection the app reads, this one is written *by the
/// app*: any user with access to the event may add media (see the gallery rules
/// in the admin panel's `firestore.rules`), and any user may flag one as
/// reported.
///
/// [thumbUrl] is only set for videos, where a poster frame is generated on the
/// device at upload time and stored next to the file — a grid of videos would
/// otherwise have to download and decode every clip just to draw its tiles.
/// Photos are drawn from [mediaUrl] at tile size, as the tips gallery does.
class GalleryMedia {
  final String id;

  /// The download URL of the uploaded file.
  final String mediaUrl;

  /// A poster frame for a video, or null — always null for a photo.
  final String? thumbUrl;

  /// The uid of the user who uploaded it.
  final String uploadedBy;

  final GalleryMediaType type;

  /// When the upload landed. Null only for the moment between a local write and
  /// the server resolving its `serverTimestamp()`.
  final DateTime? uploadedAt;

  /// Whether someone has reported this media. Nothing in the app hides reported
  /// media — it is a flag for the admin panel to moderate on.
  final bool isReported;

  const GalleryMedia({
    required this.id,
    required this.mediaUrl,
    required this.thumbUrl,
    required this.uploadedBy,
    required this.type,
    required this.uploadedAt,
    required this.isReported,
  });

  bool get isVideo => type == GalleryMediaType.video;

  /// What to load when drawing this media small: a video's poster frame if one
  /// was stored, otherwise the file itself.
  String get thumb => thumbUrl ?? mediaUrl;

  factory GalleryMedia.fromJson(Map<String, dynamic> json) {
    final mediaUrl = json['mediaUrl'] as String? ?? '';
    final thumbUrl = json['thumbUrl'] as String?;

    return GalleryMedia(
      id: json['id'] as String? ?? '',
      mediaUrl: mediaUrl,
      thumbUrl: (thumbUrl == null || thumbUrl.isEmpty) ? null : thumbUrl,
      uploadedBy: json['uploadedBy'] as String? ?? '',
      type:
          GalleryMediaType.fromJson(json['type'] as String?) ??
          GalleryMediaType.inferFrom(mediaUrl),
      uploadedAt: (json['uploadedAt'] as Timestamp?)?.toDate(),
      isReported: json['isReported'] as bool? ?? false,
    );
  }

  /// The Firestore shape. [uploadedAt] is left out on purpose: uploads write
  /// `FieldValue.serverTimestamp()` instead, so the ordering of the gallery
  /// can't be shifted by a device with a wrong clock.
  Map<String, dynamic> toJson() => {
    'mediaUrl': mediaUrl,
    if (thumbUrl != null) 'thumbUrl': thumbUrl,
    'uploadedBy': uploadedBy,
    'type': type.jsonValue,
    'isReported': isReported,
  };
}

/// One day's worth of gallery media, as the screen lays it out: a date heading
/// with the grid of everything uploaded that day beneath it.
class GalleryDaySection {
  /// Midnight of the day, in local time — what the heading is formatted from.
  final DateTime day;

  /// The media of that day, newest first.
  final List<GalleryMedia> media;

  const GalleryDaySection({required this.day, required this.media});
}
