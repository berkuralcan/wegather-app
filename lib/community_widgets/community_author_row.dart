import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../global_widgets/wg_avatar.dart';

/// Who wrote something and when: their photo, their name, and how long ago.
///
/// The same line heads a post in the feed, the post on its own screen, and every
/// comment under it. [onTap] covers the photo and the name but deliberately not
/// the time, so tapping through to a profile can't be triggered by aiming at the
/// timestamp — and so the row can sit inside a card that is itself tappable.
class CommunityAuthorRow extends StatelessWidget {
  const CommunityAuthorRow({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    this.onTap,
    this.avatarSize = _avatarSize,
  });

  final String name;
  final String? imageUrl;

  /// Null between a local write and the server resolving its timestamp, in which
  /// case no time is shown rather than a wrong one.
  final DateTime? createdAt;

  /// Opens the author's profile. Null leaves the row inert.
  final VoidCallback? onTap;

  final double avatarSize;

  static const double _avatarSize = 20;

  /// Heavier than the app's default ring, so the author reads as the first thing
  /// on a card rather than dissolving into the background.
  static const double _ringWidth = 2;

  /// Space between the name and the time — enough that they read as two separate
  /// facts rather than one run-on line.
  static const double _timeGap = 19;

  @override
  Widget build(BuildContext context) {
    final time = createdAt;

    return Row(
      children: [
        Flexible(
          child: GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WgAvatar(
                  imageUrl: imageUrl,
                  size: avatarSize,
                  ringGradient: AppConfig.buttonPrimaryGradient,
                  ringWidth: _ringWidth,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    name.isEmpty ? '—' : name,
                    style: AppTextStyles.weGatherPrimaryTextStyle.copyWith(
                      color: AppConfig.emphasisColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (time != null) ...[
          const SizedBox(width: _timeGap),
          Text(
            communityRelativeTime(time),
            style: AppTextStyles.weGatherSmallTextStyle,
          ),
        ],
      ],
    );
  }
}

/// A compact relative time — "now", "5m", "3h", "2d" — falling back to a date
/// once a post is over a week old. Locale-independent by design, like the
/// gallery's day headings.
String communityRelativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('dd.MM.yyyy').format(time);
}
