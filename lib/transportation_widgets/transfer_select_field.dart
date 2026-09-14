import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';

/// One field of the transfer search form: a caption, and below it a tappable
/// box that reads as an input but opens a picker instead of a keyboard.
///
/// Deliberately dumb — it renders [value] (or [placeholder] when nothing is
/// chosen yet) and reports taps. The screen owns the selection and decides what
/// the tap opens, so the same field serves both the from/to destination pickers
/// and the date.
class TransferSelectField extends StatelessWidget {
  const TransferSelectField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.value,
    this.leadingIcon,
    this.trailingIcon = Icons.keyboard_arrow_down,
  });

  /// The caption above the box ("Departure", "Date", …).
  final String label;

  /// Shown greyed out until something is chosen.
  final String placeholder;

  /// The chosen value, or null while the field is empty.
  final String? value;

  final VoidCallback onTap;

  /// An icon inside the box, before the value — the calendar on the date field.
  final IconData? leadingIcon;

  /// The affordance at the end of the box. A chevron by default, since every
  /// one of these fields opens something.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.weGatherSmallTextStyle),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppConfig.loginPageFormBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConfig.loginPageFormBorderColor),
              ),
              child: Row(
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 18, color: AppConfig.colorTertiary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      isEmpty ? placeholder : value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isEmpty
                          ? AppTextStyles.weGatherPrimaryTextStyle.copyWith(
                              color: AppConfig.colorTertiary,
                            )
                          : AppTextStyles.weGatherPrimaryTextStyle,
                    ),
                  ),
                  if (trailingIcon != null)
                    Icon(
                      trailingIcon,
                      size: 20,
                      color: AppConfig.colorTertiary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
