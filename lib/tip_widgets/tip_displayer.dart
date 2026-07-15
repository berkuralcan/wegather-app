import 'package:flutter/material.dart';
import 'package:wegather_app/models/tips_model.dart';
import 'package:wegather_app/text_widgets/wg_text_displayer.dart';
import 'package:wegather_app/tip_widgets/gallery_displayer.dart';
import 'package:wegather_app/tip_widgets/rich_text_displayer.dart';
import 'package:wegather_app/tip_widgets/single_file_displayer.dart';

/// Renders a [TipModel] using the right displayer for its content type.
///
/// The `switch` is exhaustive over the sealed [TipContent] hierarchy, so adding
/// a new tip type is a compile error here until it is handled.
class TipDisplayer extends StatelessWidget {
  const TipDisplayer({super.key, required this.tip});

  final TipModel tip;

  @override
  Widget build(BuildContext context) {
    final content = tip.content;
    return switch (content) {
      TextTipContent() => WgTextDisplayer(title: tip.title, body: content.text),
      RichTextTipContent() => RichTextDisplayer(
        title: tip.title,
        content: content,
      ),
      GalleryTipContent() => GalleryDisplayer(
        title: tip.title,
        content: content,
      ),
      FileTipContent() => SingleFileDisplayer(
        title: tip.title,
        content: content,
      ),
    };
  }
}
