import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../models/localized_text.dart';
import '../services/external_transportation_service.dart';

/// Asks which published flight the participant wants on one leg of their trip.
///
/// Shows only the flights leaving from (or returning to) the city they already
/// picked, so the sheet is always a short list. A flight that has run out of
/// seats is shown greyed and unselectable rather than hidden — "Dolu" tells the
/// participant the flight exists and is full, which silence would not.
///
/// Resolves to null when the user backs out, leaving the field as it was.
Future<FlightAvailability?> showFlightPickerSheet(
  BuildContext context, {
  required String title,
  required List<FlightAvailability> flights,
  required String emptyLabel,
  required String fullLabel,
  required String Function(int seatsLeft) seatsLeftLabel,
  FlightAvailability? selected,
}) {
  return showModalBottomSheet<FlightAvailability>(
    context: context,
    // The sheet paints its own surface over the app's background gradient.
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _FlightPickerSheet(
      title: title,
      flights: flights,
      emptyLabel: emptyLabel,
      fullLabel: fullLabel,
      seatsLeftLabel: seatsLeftLabel,
      selected: selected,
    ),
  );
}

class _FlightPickerSheet extends StatelessWidget {
  const _FlightPickerSheet({
    required this.title,
    required this.flights,
    required this.emptyLabel,
    required this.fullLabel,
    required this.seatsLeftLabel,
    this.selected,
  });

  final String title;
  final List<FlightAvailability> flights;
  final String emptyLabel;
  final String fullLabel;
  final String Function(int seatsLeft) seatsLeftLabel;
  final FlightAvailability? selected;

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
              if (flights.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    emptyLabel,
                    style: AppTextStyles.weGatherParagraphTextStyle,
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: flights.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final availability = flights[index];
                      return _FlightOption(
                        availability: availability,
                        locale: locale,
                        fullLabel: fullLabel,
                        seatsLeftLabel: seatsLeftLabel,
                        isSelected:
                            availability.transportation.id ==
                            selected?.transportation.id,
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

/// One flight: its route and day, the airline and number when they are known
/// yet, and how many seats are left when the flight caps them.
class _FlightOption extends StatelessWidget {
  const _FlightOption({
    required this.availability,
    required this.locale,
    required this.fullLabel,
    required this.seatsLeftLabel,
    required this.isSelected,
  });

  final FlightAvailability availability;
  final WgLocale locale;
  final String fullLabel;
  final String Function(int seatsLeft) seatsLeftLabel;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final flight = availability.transportation;
    final canChoose = availability.canChoose;
    final seatsLeft = availability.seatsLeft;
    final service = flight.serviceLabel;

    final when = StringBuffer(DateFormat('dd.MM.yyyy').format(flight.date));
    if (flight.time != null) when.write(' - ${flight.time}');

    return Opacity(
      // A full flight stays visible but reads as unavailable.
      opacity: canChoose ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canChoose
              ? () => Navigator.of(context).pop(availability)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                      Text(
                        '${flight.from.labelFor(locale)} → '
                        '${flight.destination.labelFor(locale)}',
                        style: AppTextStyles.weGatherLabelTextStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        when.toString(),
                        style: AppTextStyles.weGatherSmallTextStyle,
                      ),
                      if (service.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          service,
                          style: AppTextStyles.weGatherSmallTextStyle,
                        ),
                      ],
                      // Only a capacity-limited flight has anything to say about
                      // seats; one booked to demand stays quiet.
                      if (availability.isFullyBooked) ...[
                        const SizedBox(height: 4),
                        Text(
                          fullLabel,
                          style: AppTextStyles.weGatherSmallTextStyle.copyWith(
                            color: Colors.redAccent,
                          ),
                        ),
                      ] else if (seatsLeft != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          seatsLeftLabel(seatsLeft),
                          style: AppTextStyles.weGatherSmallTextStyle,
                        ),
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
