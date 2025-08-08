import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidButton extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color tintColor;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool isActive;

  const LiquidButton({
    super.key,
    required this.child,
    this.blur = 2.0,
    this.opacity = 0.01,
    this.tintColor = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(15.85)),
    this.onTap,
    this.padding,
    this.width,
    this.height,
    this.isActive = false
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xff0e3446).withValues(alpha: 0.6), // Correct Figma color
              blurRadius: 10.0,
              offset: const Offset(-1, -1),
              spreadRadius: .3,
              blurStyle: BlurStyle.outer,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: CustomPaint(
              painter: GradientBorderPainter(
                borderRadius: borderRadius,
                borderWidth: 1.0,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.4),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isActive ? tintColor.withValues(alpha: 0.25) : tintColor.withValues(alpha: opacity),
                  borderRadius: borderRadius,
                ),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(2.0),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double borderWidth;
  final Gradient gradient;

  GradientBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final outerRRect = RRect.fromRectAndCorners(
      outerRect,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );

    final innerRect = Rect.fromLTWH(
      borderWidth,
      borderWidth,
      size.width - borderWidth * 2,
      size.height - borderWidth * 2,
    );
    final innerRRect = RRect.fromRectAndCorners(
      innerRect,
      topLeft: Radius.circular(borderRadius.topLeft.x - borderWidth),
      topRight: Radius.circular(borderRadius.topRight.x - borderWidth),
      bottomLeft: Radius.circular(borderRadius.bottomLeft.x - borderWidth),
      bottomRight: Radius.circular(borderRadius.bottomRight.x - borderWidth),
    );

    final paint = Paint()
      ..shader = gradient.createShader(outerRect);

    canvas.drawDRRect(outerRRect, innerRRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  }