import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_config.dart';

/// A circular gradient button, as used by the row of actions floating over a
/// piece of media in the gallery viewer.
///
/// Filled with [AppConfig.buttonPrimaryGradient] and lifted off the media by a
/// soft warm glow, so the actions read as buttons against whatever photo
/// happens to be behind them. The 20pt glyph sits centred in a 36pt circle,
/// which is also what makes it a comfortable target to hit — a 20pt tap area
/// over a photo would be missed as often as it is hit.
/// [WgMediaActionButton.gap] is the spacing to leave between two of them.
class WgMediaActionButton extends StatelessWidget {
  const WgMediaActionButton({
    super.key,
    required this.iconPath,
    required this.onPressed,
    this.semanticLabel,
    this.child,
  });

  /// The SVG to draw, unless [child] replaces it. Painted in
  /// [AppConfig.lightIconColor] whatever colour the file itself carries, so one
  /// icon set works on every surface in the app.
  final String iconPath;

  /// Tap handler. Pass null to render the button as inert — used while an
  /// action it started (a download, say) is still running.
  final VoidCallback? onPressed;

  final String? semanticLabel;

  /// Drawn in place of [iconPath] when set — a progress spinner, for instance.
  final Widget? child;

  /// The gap to leave between neighbouring buttons.
  static const double gap = 4;

  /// Size of the glyph inside the button.
  static const double iconSize = 20;

  /// Diameter of the button.
  static const double size = 36;

  /// The glow around the button: `0 0 16px rgba(201, 123, 34, 0.20)` — no
  /// offset, so it sits evenly all the way round rather than reading as a drop
  /// shadow with a light source.
  static const BoxShadow _glow = BoxShadow(
    color: Color(0x33C97B22),
    blurRadius: 16,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          // Centres whatever is inside, so the glyph sits on the circle's own
          // middle no matter what size it is drawn at.
          alignment: Alignment.center,
          // A circle rather than a rounded square: at this size a corner radius
          // reads as an almost-circle, which looks like a mistake next to the
          // round avatars and badges elsewhere in the app.
          decoration: const BoxDecoration(
            gradient: AppConfig.buttonPrimaryGradient,
            shape: BoxShape.circle,
            boxShadow: [_glow],
          ),
          child:
              child ??
              SvgPicture.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
                colorFilter: const ColorFilter.mode(
                  AppConfig.lightIconColor,
                  BlendMode.srcIn,
                ),
              ),
        ),
      ),
    );
  }
}
