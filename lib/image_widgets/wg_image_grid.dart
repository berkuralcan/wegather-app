import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/gallery_image.dart';
import 'wg_image_viewer.dart';

/// A square-tiled image grid, four to a row, in the style of the iOS Photos
/// app. Tapping a tile opens [WgImageViewer] at that image.
///
/// Universal on purpose: it takes plain [GalleryImage]s, so any feature holding
/// a list of image URLs can drop it in. Tiles stay perfect squares at every
/// screen width — the tile is whatever is left once the 4pt gutters are removed.
///
/// Set [shrinkWrap] (with [physics] disabled) to embed the grid inside another
/// scroll view; leave both alone when the grid is the scrollable itself, since
/// only then does it build tiles lazily.
class WgImageGrid extends StatelessWidget {
  const WgImageGrid({
    super.key,
    required this.images,
    this.title,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
    this.physics,
    this.onTap,
    this.overlayBuilder,
  });

  final List<GalleryImage> images;

  /// Shown in the viewer's app bar when a tile is tapped.
  final String? title;

  final EdgeInsets padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// What tapping the tile at an index does. Defaults to opening
  /// [WgImageViewer] on the whole set at that index; pass a callback when the
  /// grid holds something the plain image viewer can't show, such as the event
  /// gallery's mix of photos and videos.
  final ValueChanged<int>? onTap;

  /// Drawn on top of the tile at an index — a video's play badge, say. Return
  /// null to leave a tile bare. The overlay does not receive taps; [onTap]
  /// covers the whole tile.
  final Widget? Function(BuildContext context, int index)? overlayBuilder;

  /// Gap between tiles, horizontally and vertically.
  static const double _spacing = 4;
  static const int _columns = 4;

  @override
  Widget build(BuildContext context) {
    // Decode each tile at the size it is actually drawn, not the size it was
    // uploaded at. A 4000px camera JPEG costs ~64MB of memory decoded at full
    // size and ~0.2MB decoded at tile size; without this a screenful of tiles
    // is enough to get the app killed for memory on an older phone.
    final tileWidth =
        (MediaQuery.sizeOf(context).width -
            padding.horizontal -
            _spacing * (_columns - 1)) /
        _columns;
    final cacheWidth = (tileWidth * MediaQuery.devicePixelRatioOf(context))
        .round();

    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      // Lazy: only tiles near the viewport are built, so only their images are
      // fetched and decoded. A 500-image gallery costs the same as a 20-image
      // one until the user scrolls.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        crossAxisSpacing: _spacing,
        mainAxisSpacing: _spacing,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) => _GalleryTile(
        images: images,
        index: index,
        title: title,
        cacheWidth: cacheWidth,
        onTap: onTap,
        overlay: overlayBuilder?.call(context, index),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.images,
    required this.index,
    required this.title,
    required this.cacheWidth,
    required this.onTap,
    required this.overlay,
  });

  final List<GalleryImage> images;
  final int index;
  final String? title;
  final int cacheWidth;
  final ValueChanged<int>? onTap;
  final Widget? overlay;

  /// The default tap: the plain image viewer, over the whole set.
  void _openViewer(BuildContext context) {
    // Pushed on the root navigator so the viewer covers the bottom nav bar.
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) =>
            WgImageViewer(images: images, initialIndex: index, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = images[index].thumb;
    // An empty thumb is "there is nothing to draw here", not a failure: it is
    // how a caller says the tile's picture lives in its overlay instead (the
    // gallery's videos, when no poster frame could be generated). Asking the
    // image loader for it would fetch nothing useful at best, and a whole video
    // file at worst.
    final image = url.isEmpty
        ? const WgImagePlaceholder()
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            memCacheWidth: cacheWidth,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, _) => const WgImagePlaceholder(),
            errorWidget: (_, _, _) => const WgImagePlaceholder(failed: true),
          );

    return GestureDetector(
      onTap: () => onTap == null ? _openViewer(context) : onTap!.call(index),
      child: overlay == null
          ? image
          : Stack(
              fit: StackFit.expand,
              children: [
                image,
                // Ignores pointers so the tile's own tap still lands.
                IgnorePointer(child: overlay!),
              ],
            ),
    );
  }
}

/// The neutral block shown while an image loads, or in place of one that
/// failed. Shared so a loading tile and a loading full-size image match.
class WgImagePlaceholder extends StatelessWidget {
  const WgImagePlaceholder({super.key, this.failed = false});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConfig.loginPageFormBgColor,
      alignment: Alignment.center,
      child: failed
          ? const Icon(
              Icons.broken_image_outlined,
              color: AppConfig.colorTertiary,
              size: 24,
            )
          : null,
    );
  }
}
