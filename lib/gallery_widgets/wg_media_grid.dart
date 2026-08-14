import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../image_widgets/wg_image_grid.dart';
import '../models/gallery_image.dart';
import '../models/gallery_media.dart';

/// A grid of gallery media — the tips gallery's [WgImageGrid], given photos and
/// videos instead of plain image URLs.
///
/// The tiles are the same in every way that shows: four to a row, square, 4pt
/// gutters, decoded at tile size. A video tile draws the poster frame stored
/// with it and wears a play badge, so the two kinds are told apart at a glance
/// while the grid itself stays one implementation.
class WgMediaGrid extends StatelessWidget {
  const WgMediaGrid({
    super.key,
    required this.media,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<GalleryMedia> media;

  /// Called with the index within [media] of the tapped tile.
  final ValueChanged<int> onTap;

  final EdgeInsets padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return WgImageGrid(
      // A video is drawn from its poster frame or not at all — never from the
      // video file, which the image loader would download in full before
      // failing to decode it. An empty url leaves the tile to the badge below.
      images: media
          .map(
            (item) =>
                GalleryImage(item.isVideo ? (item.thumbUrl ?? '') : item.thumb),
          )
          .toList(growable: false),
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      onTap: onTap,
      overlayBuilder: (context, index) =>
          media[index].isVideo ? _VideoBadge(media: media[index]) : null,
    );
  }
}

/// What marks a tile as a video: a play glyph, over a scrim dark enough to keep
/// it legible on a bright poster frame.
///
/// A video uploaded before poster frames existed — or one whose frame the
/// device failed to generate — has nothing to draw underneath, and the tile
/// would otherwise show a broken-image icon. The badge covers it completely in
/// that case, so the tile reads as a video rather than as a failure.
class _VideoBadge extends StatelessWidget {
  const _VideoBadge({required this.media});

  final GalleryMedia media;

  @override
  Widget build(BuildContext context) {
    final hasPoster = media.thumbUrl != null;

    return Container(
      color: hasPoster
          ? Colors.black.withValues(alpha: 0.15)
          // Opaque: there is a blank placeholder underneath, and the tile
          // should read as a video rather than as a missing image.
          : AppConfig.appDarkBackgroundGradient.colors.first,
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_circle_outline,
        size: 28,
        color: AppConfig.lightIconColor,
      ),
    );
  }
}
