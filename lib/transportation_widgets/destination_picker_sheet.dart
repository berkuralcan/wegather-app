import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../models/localized_text.dart';
import '../models/transportation_model.dart';

/// Asks which destination a transfer should leave from, or arrive at.
///
/// [title] names which end of the journey is being picked, and [excluded] drops
/// the destination already chosen for the other end — a transfer never runs from
/// a place to itself. [selected] is ticked so reopening the sheet shows the
/// current choice.
///
/// Resolves to null when the user backs out (tapping outside, dragging down, or
/// pressing back), which leaves the field as it was.
Future<DestinationModel?> showDestinationPickerSheet(
  BuildContext context, {
  required String title,
  required List<DestinationModel> destinations,
  DestinationModel? selected,
  DestinationModel? excluded,
}) {
  return showModalBottomSheet<DestinationModel>(
    context: context,
    // The sheet paints its own surface over the app's background gradient.
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _DestinationPickerSheet(
      title: title,
      destinations: destinations
          .where((d) => d.id != excluded?.id)
          .toList(growable: false),
      selected: selected,
    ),
  );
}

class _DestinationPickerSheet extends StatelessWidget {
  const _DestinationPickerSheet({
    required this.title,
    required this.destinations,
    this.selected,
  });

  final String title;
  final List<DestinationModel> destinations;
  final DestinationModel? selected;

  static const double _padding = 16;
  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final locale = WgLocale.fromJson(
      Localizations.localeOf(context).languageCode,
    );

    return Container(
      width: double.infinity,
      // Never more than two thirds of the screen: a long list scrolls inside
      // the sheet rather than pushing it over the whole page.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.66,
      ),
      decoration: const BoxDecoration(
        gradient: AppConfig.appDarkBackgroundGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(_padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: _Handle()),
              const SizedBox(height: _padding),
              Text(title, style: AppTextStyles.weGatherHeading2TextStyle),
              const SizedBox(height: _padding),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: destinations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final destination = destinations[index];
                    return _DestinationOption(
                      destination: destination,
                      locale: locale,
                      isSelected: destination.id == selected?.id,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One destination: the short handle the pickers go by, and — when it differs —
/// the real name underneath, so "Hotel" is still identifiably "Rixos Hotel".
class _DestinationOption extends StatelessWidget {
  const _DestinationOption({
    required this.destination,
    required this.locale,
    required this.isSelected,
  });

  final DestinationModel destination;
  final WgLocale locale;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final label = destination.labelFor(locale);
    final name = destination.name.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(destination),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: AppConfig.loginPageFormBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppConfig.emphasisColor
                  : AppConfig.loginPageFormBorderColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.weGatherLabelTextStyle),
                    if (name.isNotEmpty && name != label) ...[
                      const SizedBox(height: 4),
                      Text(name, style: AppTextStyles.weGatherSmallTextStyle),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check,
                  size: 20,
                  color: AppConfig.emphasisColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The grab bar at the top of the sheet.
class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppConfig.colorTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
