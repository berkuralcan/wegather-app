import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/image_widgets/wg_image_grid.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/gallery_image.dart';
import 'package:wegather_app/models/tips_model.dart';

/// Displays a gallery tip as a grid of its images.
///
/// Everything here is presentation-free on purpose — [WgImageGrid] and the
/// viewer it opens hold the layout, so any other feature with image URLs gets
/// the same behaviour for free.
class GalleryDisplayer extends StatelessWidget {
  const GalleryDisplayer({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final GalleryTipContent content;

  /// Horizontal inset of the grid, matching the app bar back arrow's glyph.
  static const double _horizontalInset = 16;

  @override
  Widget build(BuildContext context) {
    final images = content.imageUrls
        .map((url) => GalleryImage(url))
        .toList(growable: false);

    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: SafeArea(
        top: false,
        child: images.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No images yet.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.weGatherParagraphTextStyle,
                  ),
                ),
              )
            // Inset so the first tile's left edge lines up with the app bar's
            // back arrow: the arrow sits in a 56pt leading slot, centred as a
            // 40pt button with 8pt of internal padding, which puts its glyph
            // 16pt from the screen edge. Mirrored on the right.
            : WgImageGrid(
                images: images,
                title: title,
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalInset,
                ),
              ),
      ),
    );
  }
}
