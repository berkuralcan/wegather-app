import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wegather_app/config/app_config.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/reusableWidgets/gradient_underline_border.dart';

/// A horizontal strip of dates, one of which is selected.
///
/// The widget is deliberately dumb: it renders [days], marks [selectedDay] and
/// reports taps through [onDaySelected]. The parent owns the selection, so the
/// same picker can drive a schedule, a filter, or anything else.
///
/// Every date is rendered at full width — when they don't all fit, the strip
/// scrolls instead of shrinking or wrapping. The selected date is scrolled back
/// into view whenever it changes from the outside (e.g. the initial "today").
class WgDatePicker extends StatefulWidget {
  const WgDatePicker({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
    this.spacing = 24,
    this.dateFormat = 'dd/MM/yyyy',
  });

  /// The dates to offer, in the order they should appear.
  final List<DateTime> days;

  /// The currently selected date, or null while nothing is selected. Matched
  /// against [days] by calendar day, not by exact instant.
  final DateTime? selectedDay;

  /// Called with the tapped date — including one that is already selected.
  final ValueChanged<DateTime> onDaySelected;

  /// Gap between two dates.
  final double spacing;

  /// How each date is written, as an [DateFormat] pattern.
  final String dateFormat;

  @override
  State<WgDatePicker> createState() => _WgDatePickerState();
}

class _WgDatePickerState extends State<WgDatePicker> {
  /// One key per rendered date, so the selected one can be scrolled to.
  final Map<DateTime, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _scheduleScrollToSelected();
  }

  @override
  void didUpdateWidget(WgDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay) {
      _scheduleScrollToSelected();
    }
  }

  /// Bring the selected date into view after the frame it was laid out in —
  /// its render object doesn't exist before that.
  ///
  /// Deliberately the strip's own position rather than [Scrollable.ensureVisible],
  /// which walks up *every* enclosing scrollable: on a page that scrolls as a
  /// whole (a participant's Event tab) that one would drag the page itself to
  /// centre the date vertically, which nobody asked it to do.
  void _scheduleScrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = widget.selectedDay;
      if (!mounted || selected == null) return;
      final context = _itemKeys[_dayKey(selected)]?.currentContext;
      final item = context?.findRenderObject();
      if (context == null || item == null) return;
      Scrollable.maybeOf(context)?.position.ensureVisible(
        item,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Dates are compared by calendar day: a selection that carries a time of day
  /// still matches the midnight-based entries in [WgDatePicker.days].
  DateTime _dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    final format = DateFormat(widget.dateFormat);
    final selected = widget.selectedDay == null
        ? null
        : _dayKey(widget.selectedDay!);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, day) in widget.days.indexed) ...[
            if (index > 0) SizedBox(width: widget.spacing),
            _DateItem(
              key: _itemKeys.putIfAbsent(_dayKey(day), GlobalKey.new),
              label: format.format(day),
              isSelected: _dayKey(day) == selected,
              onTap: () => widget.onDaySelected(day),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single date: its label plus the indicator that marks the selection.
class _DateItem extends StatelessWidget {
  const _DateItem({
    super.key,
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
      // The indicator is the label's bottom border: it takes the width of the
      // date for free, and reserving it on every item (transparent when not
      // selected) keeps the row from shifting as the selection moves.
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: GradientUnderlineBorder(
            gradient: isSelected ? AppConfig.buttonPrimaryGradient : null,
          ),
        ),
        child: Text(
          label,
          style: isSelected
              ? AppTextStyles.weGatherSmallHeaderTextStyle
              : AppTextStyles.weGatherSmallHeaderTextStyleUnselected,
        ),
      ),
    );
  }
}
