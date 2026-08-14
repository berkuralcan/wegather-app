import 'package:flutter/material.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';

/// A full-width strip of pill-shaped tabs, one of which is selected.
///
/// The widget is deliberately dumb, like the calendar's date picker: it renders [labels],
/// marks [selectedIndex] and reports taps through [onSelected]. The parent owns
/// the selection, so the same strip can switch a page's content, filter a list,
/// or anything else.
///
/// Every tab takes an equal share of the available width, so the strip fills its
/// parent whether it holds two labels or four.
class WgTabSelector extends StatelessWidget {
  const WgTabSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// The tabs to offer, in the order they should appear — already localised.
  final List<String> labels;

  /// The index into [labels] that is currently selected.
  final int selectedIndex;

  /// Called with the tapped tab's index — including one already selected.
  final ValueChanged<int> onSelected;

  /// The gap between the track and the pills inside it.
  static const double _trackPadding = 4;

  /// Height of a pill above and below its label.
  static const double _pillPadding = 8;

  /// Corner radius of the track and of the selected pill alike.
  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_trackPadding),
      decoration: BoxDecoration(
        color: AppConfig.primaryFillColor,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Row(
        children: [
          for (final (index, label) in labels.indexed)
            Expanded(
              child: _Tab(
                label: label,
                isSelected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
            ),
        ],
      ),
    );
  }
}

/// One tab: its label, and the fill that marks it as the selected one.
class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: WgTabSelector._pillPadding,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppConfig.activeButtonFillGradient : null,
          borderRadius: BorderRadius.circular(WgTabSelector._radius),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: isSelected
              ? AppTextStyles.weGatherTabTextStyle
              : AppTextStyles.weGatherTabTextStyle.copyWith(
                  color: AppConfig.colorTertiary,
                ),
        ),
      ),
    );
  }
}
