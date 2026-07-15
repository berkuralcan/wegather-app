import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/tips_model.dart';

/// Displays a single-file tip.
///
/// Placeholder for now — will render/download the file at [content.fileUrl].
class SingleFileDisplayer extends StatelessWidget {
  const SingleFileDisplayer({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final FileTipContent content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'File displayer — coming soon.\n${content.fileUrl}',
            textAlign: TextAlign.center,
            style: AppTextStyles.weGatherParagraphTextStyle,
          ),
        ),
      ),
    );
  }
}
