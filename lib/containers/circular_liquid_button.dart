import 'dart:ui';
import 'package:flutter/material.dart';

class CircularLiquidButton extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color tintColor;
  final double size;
  final VoidCallback? onTap;

  const CircularLiquidButton({
    super.key,
    required this.child,
    this.blur = 2.0,
    this.opacity = 0.01,
    this.tintColor = Colors.white,
    this.size = 50.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    final borderRadius = BorderRadius.circular(radius);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xff0e3446).withValues(alpha: 0.8), // Correct Figma color
              blurRadius: 8.0,
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
              painter: CircularGradientBorderPainter(
                radius: radius,
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
                  color: tintColor.withValues(alpha: opacity),
                  borderRadius: borderRadius,
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CircularGradientBorderPainter extends CustomPainter {
  final double radius;
  final double borderWidth;
  final Gradient gradient;

  CircularGradientBorderPainter({
    required this.radius,
    required this.borderWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    final paint = Paint()
      ..shader = gradient.createShader(outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw only the border circle with stroke style
    canvas.drawCircle(center, radius - (borderWidth / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}