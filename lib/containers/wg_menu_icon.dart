import 'package:flutter/material.dart';
import 'package:wegather_app/containers/liquid_container.dart';
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
      child: LiquidContainer(
        child: Column(
          children: [
            Spacer(),
            SizedBox(
              width: 55,
              height: 55,
              child: Center(child: Image.asset(iconPath, width: iconSize.width, height: iconSize.height))
            ),
            SizedBox(height: 5),
            Text(title, style: AppTextStyles.menuIconTextStyle),
            Spacer(),
          ],
        ),
      ),
    );
  }
}