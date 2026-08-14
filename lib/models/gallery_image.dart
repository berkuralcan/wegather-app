/// One image in a gallery: the full-size file, plus an optional smaller variant
/// to use wherever the image is drawn at thumbnail size.
///
/// [thumbUrl] is null everywhere today because uploads store only the original —
/// the admin panel's `useStorageUpload.ts` does not resize. Both [WgImageGrid]
/// and the viewer's filmstrip already read [thumb] rather than [url], so once
/// the panel starts writing a resized copy, filling in this field is the only
/// change needed to stop pulling multi-megabyte originals into 95pt tiles.
class GalleryImage {
  /// The full-size image, shown in the viewer.
  final String url;

  /// A smaller copy of [url], if one exists.
  final String? thumbUrl;

  const GalleryImage(this.url, {this.thumbUrl});

  /// What to load when drawing the image small. Falls back to the original.
  String get thumb => thumbUrl ?? url;
}
