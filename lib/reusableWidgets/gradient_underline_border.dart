import 'package:flutter/material.dart';

/// A bottom-only [BoxBorder] painted with a [Gradient].
///
/// [BorderSide] only carries a flat colour, so a gradient underline has to be
/// drawn by hand. This border does that: it reserves [width] at the bottom of
/// the box and fills that strip with [gradient].
///
/// Passing a null [gradient] still reserves the strip but paints nothing, so an
/// indicator can come and go without the content around it shifting.
///
/// Only the bottom side is drawn — [top], [left] and [right] are always
/// [BorderSide.none] — and the line is a plain rectangle, so a `borderRadius`
/// on the surrounding [BoxDecoration] does not round its ends.
@immutable
class GradientUnderlineBorder extends BoxBorder {
  const GradientUnderlineBorder({required this.gradient, this.width = 2});

  /// The gradient the line is filled with, or null to reserve the space and
  /// leave it empty.
  final Gradient? gradient;

  /// Thickness of the line, in logical pixels. Reserved whether or not
  /// [gradient] is set.
  final double width;

  @override
  BorderSide get top => BorderSide.none;

  @override
  BorderSide get bottom => BorderSide(
    color: gradient?.colors.first ?? Colors.transparent,
    width: width,
  );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(bottom: width);

  @override
  bool get isUniform => false;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final gradient = this.gradient;
    if (gradient == null || width <= 0) {
      return;
    }
    final line = Rect.fromLTWH(
      rect.left,
      rect.bottom - width,
      rect.width,
      width,
    );
    canvas.drawRect(line, Paint()..shader = gradient.createShader(line));
  }

  @override
  GradientUnderlineBorder scale(double t) =>
      GradientUnderlineBorder(gradient: gradient?.scale(t), width: width * t);

  @override
  bool operator ==(Object other) =>
      other is GradientUnderlineBorder &&
      other.gradient == gradient &&
      other.width == width;

  @override
  int get hashCode => Object.hash(gradient, width);
}
