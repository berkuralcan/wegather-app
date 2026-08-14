import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../config/app_config.dart';
import '../image_widgets/wg_image_grid.dart';

/// One video, played in place at its own aspect ratio.
///
/// Tapping anywhere on the frame toggles playback, and a scrubber sits along
/// the bottom. Only the page a pager is actually showing plays: [isActive] goes
/// false as soon as the user swipes away, which pauses the video rather than
/// leaving it running (and audible) behind whatever they swiped to.
///
/// The poster frame stored with the video — see `GalleryService.upload` — fills
/// the frame while the first bytes are still arriving, so a video opens onto a
/// still of itself rather than a black rectangle.
class WgVideoPlayer extends StatefulWidget {
  const WgVideoPlayer({
    super.key,
    required this.url,
    required this.isActive,
    this.posterUrl,
  });

  final String url;

  /// False for the off-screen pages a pager keeps ready on either side.
  final bool isActive;

  final String? posterUrl;

  @override
  State<WgVideoPlayer> createState() => _WgVideoPlayerState();
}

class _WgVideoPlayerState extends State<WgVideoPlayer> {
  late final VideoPlayerController _controller;

  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _initialized = true);
          _controller.setLooping(true);
          if (widget.isActive) _controller.play();
        })
        .catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void didUpdateWidget(WgVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive || !_initialized) return;
    // Playback follows the page: swiping to a video starts it, the same way
    // opening one does, and swiping away stops it rather than leaving it
    // running (and audible) behind whatever the user swiped to.
    widget.isActive ? _controller.play() : _controller.pause();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (!_initialized) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(child: WgImagePlaceholder(failed: true));
    }
    if (!_initialized) return _buildPoster();

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          // Rebuilt on every frame of playback, so the badge and the scrubber
          // follow the video without the whole page doing so.
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller,
            builder: (context, value, _) => Stack(
              alignment: Alignment.center,
              children: [
                if (!value.isPlaying) const _PlayBadge(),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppConfig.emphasisColor,
                      bufferedColor: AppConfig.colorTertiary,
                      backgroundColor: AppConfig.dividerNonOpaqueColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// What fills the frame until the video is ready to draw itself: its poster
  /// frame if it has one, with a spinner over it.
  Widget _buildPoster() {
    final posterUrl = widget.posterUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (posterUrl != null)
          CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.contain),
        const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ],
    );
  }
}

/// The play glyph shown over a paused video.
class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppConfig.primaryFillColor,
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        size: 40,
        color: AppConfig.lightIconColor,
      ),
    );
  }
}
