import 'package:flutter/material.dart';
import '../containers/liquid_container.dart';
import '../config/text_styles.dart';

/// A custom SnackBar widget with LiquidContainer styling
class LiquidSnackBar extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? iconColor;

  const LiquidSnackBar({
    super.key,
    required this.message,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: LiquidContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    icon!,
                    color: iconColor ?? Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.lightButtonTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a liquid-themed SnackBar with LiquidContainer styling
void showLiquidSnackBar(
  BuildContext context,
  String message, {
  IconData? icon,
  Color? iconColor,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: LiquidSnackBar(
        message: message,
        icon: icon,
        iconColor: iconColor,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    ),
  );
}
