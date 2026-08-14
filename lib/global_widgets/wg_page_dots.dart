import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Which page of a carousel is on screen: one dot per page, the current one
/// filled and the rest dimmed.
///
/// Purely a readout — it reports a position rather than offering one, so the
/// pager above it stays the only thing that moves between pages.
class WgPageDots extends StatelessWidget {
  const WgPageDots({super.key, required this.count, required this.current});

  final int count;

  /// The zero-based page being shown.
  final int current;

  static const double _size = 6;
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < count; index++)
          Container(
            width: _size,
            height: _size,
            margin: const EdgeInsets.symmetric(horizontal: _gap / 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == current
                  ? AppConfig.lightIconColor
                  : AppConfig.colorTertiary,
            ),
          ),
      ],
    );
  }
}
