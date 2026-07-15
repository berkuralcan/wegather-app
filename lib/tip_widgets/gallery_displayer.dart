import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/tips_model.dart';

/// Displays a gallery tip.
///
/// Placeholder for now — will render the images in [content.imageUrls].
class GalleryDisplayer extends StatelessWidget {
  const GalleryDisplayer({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final GalleryTipContent content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Gallery displayer — coming soon.\n${content.imageUrls.length} image(s)',
            textAlign: TextAlign.center,
            style: AppTextStyles.weGatherParagraphTextStyle,
          ),
        ),
      ),
    );
  }
}
