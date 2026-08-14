import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wegather_app/config/app_config.dart';

/// A circular profile photo inside the app's gradient ring.
///
/// Falls back to the app's placeholder both when there is no photo and when the
/// one there is fails to load, so the ring is never empty.
///
/// The ring defaults to the dark gradient, which reads as a quiet rim wherever a
/// photo needs separating from what's behind it. Somewhere the avatar should
/// carry more weight — a post's author in the feed, say — [ringGradient] and
/// [ringWidth] make it a deliberate accent instead.
class WgAvatar extends StatelessWidget {
  const WgAvatar({
    super.key,
    required this.imageUrl,
    required this.size,
    this.ringGradient = AppConfig.appDarkBackgroundGradient,
    this.ringWidth = _defaultRingWidth,
  });

  /// The photo to show — null or empty draws the placeholder.
  final String? imageUrl;

  /// Diameter of the photo, inside its ring. The widget itself is [size] plus
  /// the ring on either side.
  final double size;

  /// The gradient the ring is filled with.
  final Gradient ringGradient;

  /// Thickness of the ring drawn around the photo.
  final double ringWidth;

  static const double _defaultRingWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? '';
    // Decode at the size the photo is actually drawn at — a full-size portrait
    // costs orders of magnitude more memory than a small circle needs.
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    // A [Border] only carries a flat colour, so the ring is instead the
    // gradient-filled circle underneath, with the photo inset by [ringWidth].
    return Container(
      width: size + ringWidth * 2,
      height: size + ringWidth * 2,
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: ringGradient),
      child: ClipOval(
        child: url.isEmpty
            ? _placeholder()
            : CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: cacheSize,
                memCacheHeight: cacheSize,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) => _placeholder(),
                errorWidget: (_, _, _) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() => Image.asset(
    AppConfig.noProfileImage,
    width: size,
    height: size,
    fit: BoxFit.cover,
  );
}
