import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../models/community_model.dart';

/// Text that has been through the composer: `@[name](uid)` tokens drawn as
/// accented `@name`, everything else left as it was written.
///
/// Both a post's caption and a comment's body are stored in that form, so both
/// are drawn with this.
class MentionText extends StatelessWidget {
  const MentionText({super.key, required this.text, this.style, this.maxLines});

  /// The raw stored text, mention tokens and all.
  final String text;

  /// The style of the literal text; mentions are this style accented. Defaults
  /// to the app's primary body style.
  final TextStyle? style;

  /// Caps the text at this many lines, ellipsising what is left — for previews
  /// where the height is fixed. Null lets it run as long as it was written.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final base = style ?? AppTextStyles.weGatherPrimaryTextStyle;

    return RichText(
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
      text: TextSpan(
        style: base,
        children: Mentions.render(text).map((span) {
          if (span.isMention) {
            return TextSpan(
              text: '@${span.name}',
              style: base.copyWith(
                color: AppConfig.accentColor,
                fontWeight: FontWeight.w600,
              ),
            );
          }
          return TextSpan(text: span.text);
        }).toList(),
      ),
    );
  }
}
