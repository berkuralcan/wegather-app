import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/tips_model.dart';

/// Displays a rich-text tip.
///
/// Placeholder for now — will render the ordered [content.blocks].
class RichTextDisplayer extends StatelessWidget {
  const RichTextDisplayer({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final RichTextTipContent content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Rich text displayer — coming soon.\n${content.blocks.length} block(s)',
            textAlign: TextAlign.center,
            style: AppTextStyles.weGatherParagraphTextStyle,
          ),
        ),
      ),
    );
  }
}
