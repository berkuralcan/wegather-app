import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../gallery_widgets/wg_video_player.dart';
import '../global_widgets/wg_page_dots.dart';
import '../models/community_model.dart';

/// A post's media in a square, swipeable when there is more than one, with a
/// counter and dots to say where in the carousel you are.
///
/// It stays cheap in a scrolling feed: [PageView.builder] builds the page on
/// screen and its neighbours, so a card at rest decodes one image and a fast
/// scroll past it never decodes the rest of the carousel.
///
/// [playVideos] is what separates the two places this is used. In the feed a
/// video is its poster frame under a play glyph — a list of cards that all start
/// playing is neither wanted nor affordable — while on the post's own screen the
/// video plays in place, and only the page you are looking at plays.
class CommunityMediaCarousel extends StatefulWidget {
  const CommunityMediaCarousel({
    super.key,
    required this.media,
    this.playVideos = false,
  });

  final List<CommunityMedia> media;

  final bool playVideos;

  @override
  State<CommunityMediaCarousel> createState() => _CommunityMediaCarouselState();
}

class _CommunityMediaCarouselState extends State<CommunityMediaCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final width = MediaQuery.sizeOf(context).width;
    final cacheWidth = (width * MediaQuery.devicePixelRatioOf(context)).round();

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: media.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              final item = media[index];
              if (widget.playVideos && item.isVideo) {
                return WgVideoPlayer(
                  url: item.url,
                  isActive: index == _page,
                  posterUrl: item.thumbUrl,
                );
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: item.thumb,
                    fit: BoxFit.cover,
                    memCacheWidth: cacheWidth,
                    fadeInDuration: const Duration(milliseconds: 150),
                    placeholder: (_, _) =>
                        Container(color: AppConfig.primaryFillColor),
                    errorWidget: (_, _, _) =>
                        Container(color: AppConfig.primaryFillColor),
                  ),
                  if (item.isVideo)
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                ],
              );
            },
          ),
          if (media.length > 1) ...[
            Positioned(
              top: 10,
              right: 10,
              child: _Badge(label: '${_page + 1}/${media.length}'),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: WgPageDots(count: media.length, current: _page),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The "2/3" pill over a carousel. Dark enough to stay legible over whatever
/// photo happens to be under it.
class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.collections, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.weGatherSmallTextStyle.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
