import 'package:flutter/material.dart';
import 'package:wegather_app/config/app_config.dart';

/// A pill-shaped button painted with [AppConfig.buttonPrimaryGradient].
///
/// It does not impose a width of its own — it fills whatever width its parent
/// gives it. Wrap it in a `SizedBox(width: double.infinity)` (or `Expanded`)
/// to make it full-width, or leave it unconstrained to size to its label.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.minHeight = 48,
  });

  final String label;

  /// An optional glyph before the label, drawn at the label's size.
  final Widget? icon;

  /// Tap handler. Pass `null` to render the button as disabled.
  final VoidCallback? onPressed;

  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppConfig.buttonPrimaryGradient,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
