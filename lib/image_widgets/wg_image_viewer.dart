import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../layouts/wegather_appbar.dart';
import '../models/gallery_image.dart';
import 'wg_image_grid.dart';
import 'wg_zoomable_image.dart';

/// Full-screen image viewer: one image at a time over the app background, with
/// a filmstrip of the whole set beneath it.
///
/// Swipe left/right to move between images, pinch or double-tap to zoom, or tap
/// a filmstrip thumbnail to jump straight to it. Universal — it takes plain
/// [GalleryImage]s, so it is not tied to tips.
///
/// Usually reached by tapping a tile in [WgImageGrid], but fine to push
/// directly (e.g. with a single image and no filmstrip).
class WgImageViewer extends StatefulWidget {
  const WgImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.title,
  });

  final List<GalleryImage> images;
  final int initialIndex;
  final String? title;

  @override
  State<WgImageViewer> createState() => _WgImageViewerState();
}

class _WgImageViewerState extends State<WgImageViewer> {
  /// Filmstrip metrics. The active thumbnail widens in place; everything else
  /// stays a narrow sliver, so the strip reads as a position indicator as much
  /// as a picker.
  static const double _thumbWidth = 20;
  static const double _activeThumbWidth = 65;
  static const double _thumbHeight = 47;
  static const double _thumbRadius = 4;
  static const double _thumbGap = 4;
  static const Duration _thumbAnimation = Duration(milliseconds: 250);

  late final PageController _pageController;
  final ScrollController _filmstripController = ScrollController();

  late int _index;

  /// True while the current image is zoomed in. Paging is suspended then, so a
  /// horizontal drag pans the zoomed image instead of flipping to the next one.
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _index);
    // The filmstrip can only be measured once it has been laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerFilmstrip());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheNeighbours();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _filmstripController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
      // A new image always starts unzoomed, so paging must be re-enabled even
      // if the previous one was left zoomed in.
      _zoomed = false;
    });
    _centerFilmstrip();
    _precacheNeighbours();
  }

  /// Warms the next and previous full-size images so a swipe lands on a drawn
  /// image instead of a spinner. Only the immediate neighbours — precaching
  /// further ahead spends bandwidth on images most users never reach.
  void _precacheNeighbours() {
    for (final offset in const [-1, 1]) {
      final neighbour = _index + offset;
      if (neighbour < 0 || neighbour >= widget.images.length) continue;
      precacheImage(
        CachedNetworkImageProvider(widget.images[neighbour].url),
        context,
      );
    }
  }

  /// Scrolls the filmstrip so the active thumbnail sits in the middle. Every
  /// thumbnail before the active one is narrow, which makes the offset exact.
  void _centerFilmstrip() {
    if (!_filmstripController.hasClients) return;
    final position = _filmstripController.position;
    final target =
        _index * (_thumbWidth + _thumbGap) -
        (position.viewportDimension - _activeThumbWidth) / 2;
    _filmstripController.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: _thumbAnimation,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold and app bar are transparent, so the global background gradient
    // from main.dart shows through behind the image.
    return Scaffold(
      appBar: CustomAppBar(title: widget.title ?? ''),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: _zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemCount: widget.images.length,
                itemBuilder: (context, index) => WgZoomableImage(
                  imageUrl: widget.images[index].url,
                  isActive: index == _index,
                  onZoomChanged: (zoomed) {
                    if (index != _index || zoomed == _zoomed) return;
                    setState(() => _zoomed = zoomed);
                  },
                ),
              ),
            ),
            // A filmstrip of one is just a decoration.
            if (widget.images.length > 1) _buildFilmstrip(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFilmstrip(BuildContext context) {
    final cacheWidth =
        (_activeThumbWidth * MediaQuery.devicePixelRatioOf(context)).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: _thumbHeight,
        child: ListView.separated(
          controller: _filmstripController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.images.length,
          separatorBuilder: (_, __) => const SizedBox(width: _thumbGap),
          itemBuilder: (context, index) {
            final active = index == _index;
            return GestureDetector(
              onTap: () => _pageController.animateToPage(
                index,
                duration: _thumbAnimation,
                curve: Curves.easeOutCubic,
              ),
              child: AnimatedContainer(
                duration: _thumbAnimation,
                curve: Curves.easeOutCubic,
                width: active ? _activeThumbWidth : _thumbWidth,
                height: _thumbHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_thumbRadius),
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.images[index].thumb,
                  // Cover keeps the crop centred as the thumbnail widens, so
                  // the image grows out of its own middle rather than sliding.
                  fit: BoxFit.cover,
                  memCacheWidth: cacheWidth,
                  placeholder: (_, __) => const WgImagePlaceholder(),
                  errorWidget: (_, __, ___) =>
                      const WgImagePlaceholder(failed: true),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
