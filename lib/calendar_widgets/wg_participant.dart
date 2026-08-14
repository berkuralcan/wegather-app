import 'package:flutter/material.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/global_widgets/wg_avatar.dart';
import 'package:wegather_app/models/activity_model.dart';

/// One person in an activity's roster: their photo, their name and their title.
///
/// Text is read in the primary (Turkish) language, like the rest of the app.
/// The title line is optional on the model, so it collapses when unset.
class WgParticipant extends StatelessWidget {
  const WgParticipant({super.key, required this.participant, this.onTap});

  final ParticipantModel participant;

  /// Opens the participant's detail page. Null for a participant the roster
  /// snapshot gives no id for, which there is no page to open.
  final VoidCallback? onTap;

  /// Diameter of the photo, inside its ring.
  static const double _avatarSize = 40;

  @override
  Widget build(BuildContext context) {
    final title = participant.title;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          WgAvatar(imageUrl: participant.profileImage, size: _avatarSize),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.weGatherParagraphTextStyle,
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.weGatherPrimaryTextStyle.copyWith(
                      color: AppConfig.colorTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.chevron_right,
            color: AppConfig.emphasisColor,
            size: 24,
          ),
        ],
      ),
    );
  }
}
