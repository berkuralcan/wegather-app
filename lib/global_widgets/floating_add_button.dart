import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';

/// The floating "add something" pill: a glyph and [label] side by side on the
/// [AppConfig.buttonPrimaryGradient].
///
/// Sized to its content so it floats as a pill rather than stretching, and the
/// screen is what positions it (and spaces it off the bottom) — this is only the
/// button itself. The label, the glyph and what the tap does all belong to the
/// caller, so the same button serves the community feed, the gallery, and — with
/// [borderRadius] tightened — a committing action in an app bar, like posting.
///
/// While [isBusy] the button shows a spinner in place of its glyph and ignores
/// taps, which is what a screen wants while the work the last tap started is
/// still running.
class FloatingAddButton extends StatelessWidget {
  const FloatingAddButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.iconAsset = 'assets/icons/plus.svg',
    this.borderRadius = _pillRadius,
    this.isBusy = false,
  });

  /// The text beside the glyph — already localised.
  final String label;

  final VoidCallback onPressed;

  /// The SVG drawn before the label, painted white whatever colour the file
  /// itself carries.
  final String iconAsset;

  /// Corner radius of the fill. The default rounds the ends fully, which is what
  /// makes it read as a floating pill.
  final double borderRadius;

  /// Whether the action the button starts is still running.
  final bool isBusy;

  /// The glyph is 24×24 with an 8px gap to the label.
  static const double _iconSize = 24;
  static const double _iconGap = 8;
  static const double _pillRadius = 999;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: isBusy ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppConfig.buttonPrimaryGradient,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The spinner takes the glyph's box exactly, so the pill doesn't
              // change width when the action starts.
              SizedBox(
                width: _iconSize,
                height: _iconSize,
                child: isBusy
                    ? const Padding(
                        padding: EdgeInsets.all(2),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : SvgPicture.asset(
                        iconAsset,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
              const SizedBox(width: _iconGap),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.weGatherParagraphTextStyle.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
