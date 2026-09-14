import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../models/external_transportation_model.dart';

/// The "how are you getting here" choice at the top of the reservation form.
///
/// Two mutually exclusive options rendered as radio rows. Picking
/// [TravelType.self] is a complete answer on its own — the form's flight
/// sections collapse behind it — which is why this sits above the divider and
/// everything else below it.
class TravelPreferenceSelector extends StatelessWidget {
  const TravelPreferenceSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.selfLabel,
    required this.flightLabel,
  });

  /// The current choice, or null until the participant has answered.
  final TravelType? value;
  final ValueChanged<TravelType> onChanged;
  final String selfLabel;
  final String flightLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Option(
          label: selfLabel,
          isSelected: value == TravelType.self,
          onTap: () => onChanged(TravelType.self),
        ),
        const SizedBox(height: 4),
        _Option(
          label: flightLabel,
          isSelected: value == TravelType.flight,
          onTap: () => onChanged(TravelType.flight),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // A filled disc when unpicked, a ticked disc when picked — the
              // shape stays the same size either way so the row never shifts.
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppConfig.emphasisColor
                      : AppConfig.loginPageFormBgColor,
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.weGatherParagraphTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
