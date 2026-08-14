import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/config/app_config.dart';

/// One row of labelled information on a detail screen: a title above its
/// value, with an optional icon at the trailing edge.
///
/// When [onTap] is provided the whole row becomes tappable — used for social
/// links, where tapping opens the given profile in its native app or browser.
class WgInfoRow extends StatelessWidget {
  const WgInfoRow({
    super.key,
    required this.title,
    required this.information,
    this.icon,
    this.onTap,
  });

  final String title;
  final String information;

  /// Key into [_iconMap] — set only for rows that show an icon (social links).
  final String? icon;
  final VoidCallback? onTap;

  // TODO - If we need a substantial number of icons, we should use an enum.
  static const Map<String, String> _iconMap = {
    'linkedin': 'assets/icons/linkedin.svg',
    'instagram': 'assets/icons/instagram.svg',
    'website': 'assets/icons/website.svg',
    'portfolio': 'assets/icons/website.svg',
  };

  @override
  Widget build(BuildContext context) {
    final iconAsset = icon == null ? null : _iconMap[icon];

    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.weGatherPrimaryTextStyle.copyWith(
                  color: AppConfig.colorTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                information,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.weGatherParagraphTextStyle,
              ),
            ],
          ),
        ),
        if (iconAsset != null) ...[
          const SizedBox(width: 12),
          SvgPicture.asset(iconAsset, width: 20, height: 20),
        ],
      ],
    );

    if (onTap == null) return row;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }
}
