import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'wg_image_grid.dart';

/// One full-screen image, pinch- and double-tap zoomable, reporting its zoom
/// state so a pager around it knows when to stand down.
///
/// Shared by every full-screen viewer in the app — the tips gallery's
/// [WgImageViewer] and the event gallery's viewer alike — so zooming behaves
/// identically wherever an image fills the screen.
class WgZoomableImage extends StatefulWidget {
  const WgZoomableImage({
    super.key,
    required this.imageUrl,
    required this.isActive,
    required this.onZoomChanged,
  });

  final String imageUrl;

  /// False for the off-screen pages a pager keeps ready on either side.
  final bool isActive;

  final ValueChanged<bool> onZoomChanged;

  @override
  State<WgZoomableImage> createState() => _WgZoomableImageState();
}

class _WgZoomableImageState extends State<WgZoomableImage>
    with SingleTickerProviderStateMixin {
  static const double _maxScale = 4;
  static const double _doubleTapScale = 2.5;

  final TransformationController _transformation = TransformationController();
  late final AnimationController _animation;
  Animation<Matrix4>? _zoomAnimation;

  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _animation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        )..addListener(() {
          if (_zoomAnimation != null) {
            _transformation.value = _zoomAnimation!.value;
          }
        });
    _transformation.addListener(_reportZoom);
  }

  @override
  void didUpdateWidget(WgZoomableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Swiping away from a zoomed image leaves it zoomed underneath; reset it so
    // coming back shows the whole image again.
    if (oldWidget.isActive && !widget.isActive) _resetZoom(animated: false);
  }

  @override
  void dispose() {
    _transformation.dispose();
    _animation.dispose();
    super.dispose();
  }

  void _reportZoom() {
    final zoomed = _transformation.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _isZoomed) return;
    _isZoomed = zoomed;
    widget.onZoomChanged(zoomed);
  }

  void _animateTo(Matrix4 target) {
    _zoomAnimation = Matrix4Tween(
      begin: _transformation.value,
      end: target,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
    _animation.forward(from: 0);
  }

  void _resetZoom({bool animated = true}) {
    if (animated) {
      _animateTo(Matrix4.identity());
    } else {
      _animation.stop();
      _transformation.value = Matrix4.identity();
    }
  }

  /// Zooms in on the tapped point, or back out if already zoomed.
  void _handleDoubleTap(TapDownDetails details) {
    if (_isZoomed) {
      _resetZoom();
      return;
    }
    final position = details.localPosition;
    _animateTo(
      Matrix4.identity()
        ..translate(
          -position.dx * (_doubleTapScale - 1),
          -position.dy * (_doubleTapScale - 1),
        )
        ..scale(_doubleTapScale),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Decoded at twice the screen width: sharp at rest and through the first
    // couple of zoom steps, at a quarter of the memory a full-resolution decode
    // would cost. Raise the multiplier if deep zoom needs to stay crisp.
    final cacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context) *
                2)
            .round();

    return GestureDetector(
      onDoubleTapDown: _handleDoubleTap,
      // The callback has to exist for onDoubleTapDown to fire.
      onDoubleTap: () {},
      child: InteractiveViewer(
        transformationController: _transformation,
        minScale: 1,
        maxScale: _maxScale,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            // Contain fills the width for anything landscape while never
            // cropping — a tall portrait shot is fully visible rather than
            // having its top and bottom cut off.
            fit: BoxFit.contain,
            memCacheWidth: cacheWidth,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, _) => const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, _, _) =>
                const Center(child: WgImagePlaceholder(failed: true)),
          ),
        ),
      ),
    );
  }
}
