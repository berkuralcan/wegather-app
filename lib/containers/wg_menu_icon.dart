import 'package:flutter/material.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';

class WgMenuIcon extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback onTap;
  final Size iconSize;
  const WgMenuIcon({
    super.key,
    required this.iconPath,
    required this.title,
    required this.onTap,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.center,
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              gradient: AppConfig.menuIconBackgroundColor,
            ),
            padding: EdgeInsets.all(16),
            child: Image.asset(iconPath, width: 28, height: 28),
          ),
          SizedBox(height: 8),
          // Fixed-height label slot so every tile's text sits on the same
          // baseline; long titles scale down rather than wrap to a second line.
          SizedBox(
            height: 16,
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: AppTextStyles.menuIconTextStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
