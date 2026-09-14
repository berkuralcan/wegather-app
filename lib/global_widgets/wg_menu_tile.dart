import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';

/// One row of a menu: an icon, what it opens, and a chevron saying it opens.
///
/// The shape the documents list is built from, pulled out so every screen that
/// is really a list of places to go — your own profile's sections, for one —
/// reads the same. The icon comes in as a widget rather than an asset path,
/// since some of these are PNGs and others SVGs; [iconSize] is the side both
/// are drawn at.
class WgMenuTile extends StatelessWidget {
  const WgMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  /// The side of the icon at the head of the row, for callers to size their
  /// own artwork by.
  static const double iconSize = 24;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConfig.tipColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConfig.loginPageFormBorderColor),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: AppTextStyles.weGatherLabelTextStyle),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right,
              color: AppConfig.emphasisColor,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
