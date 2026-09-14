import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../global_widgets/wg_info_row.dart';
import '../l10n/app_localizations.dart';
import '../models/external_transportation_model.dart';
import '../models/localized_text.dart';

/// The read-only view of a travel request: who is flying, and on what.
///
/// One widget serves three moments — the review step before submitting, the
/// saved-but-not-yet-ticketed state, and the confirmed state — because they show
/// the same facts and differ only in how much of them exists yet. Each row falls
/// back to a dash rather than collapsing: a participant checking their details
/// needs to SEE that their ID number is missing, which a hidden row would not
/// tell them. (This is the opposite of the profile screen, where an unset field
/// is simply not part of the story.)
///
/// The leg blocks prefer the confirmed ticket over the flight that was
/// requested, so the same widget shows "the flight you asked for" before the
/// panel books it and "the flight you are on" afterwards.
class TravelSummary extends StatelessWidget {
  const TravelSummary({
    super.key,
    required this.passenger,
    required this.legs,
  });

  final TravelPassengerModel? passenger;
  final List<ExternalTransportationLegModel> legs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = WgLocale.fromJson(
      Localizations.localeOf(context).languageCode,
    );
    final dash = l10n.flights_notProvided;

    final arrivals = legs.where((l) => l.kind == TravelLegKind.arrival).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final departures =
        legs.where((l) => l.kind == TravelLegKind.departure).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.tipColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConfig.loginPageFormBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.flights_personalTitle,
            style: AppTextStyles.weGatherHeaderTextStyle,
          ),
          const SizedBox(height: 16),
          WgInfoRow(
            title: l10n.flights_fullName,
            information: _orDash(passenger?.fullName, dash),
          ),
          const SizedBox(height: 16),
          WgInfoRow(
            title: l10n.flights_birthDate,
            information: passenger?.birthDate == null
                ? dash
                : DateFormat('dd.MM.yyyy').format(passenger!.birthDate!),
          ),
          const SizedBox(height: 16),
          WgInfoRow(
            title: l10n.flights_gender,
            information: switch (passenger?.gender) {
              TravelGender.male => l10n.flights_genderMale,
              TravelGender.female => l10n.flights_genderFemale,
              null => dash,
            },
          ),
          const SizedBox(height: 16),
          WgInfoRow(
            title: l10n.flights_identityNumber,
            information: _orDash(passenger?.documentNumber, dash),
          ),
          const SizedBox(height: 16),
          WgInfoRow(
            title: l10n.flights_identitySerial,
            information: _orDash(passenger?.documentSerialNumber, dash),
          ),
          for (final leg in arrivals)
            _LegBlock(
              title: l10n.flights_arrivalDetailsTitle,
              leg: leg,
              locale: locale,
              dash: dash,
            ),
          for (final leg in departures)
            _LegBlock(
              title: l10n.flights_departureDetailsTitle,
              leg: leg,
              locale: locale,
              dash: dash,
            ),
        ],
      ),
    );
  }
}

/// One leg's details: where it flies, on what service, and when.
class _LegBlock extends StatelessWidget {
  const _LegBlock({
    required this.title,
    required this.leg,
    required this.locale,
    required this.dash,
  });

  final String title;
  final ExternalTransportationLegModel leg;
  final WgLocale locale;
  final String dash;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = leg.result;

    // The route always reads from the participant's own end of the journey —
    // where they take off on the way in, where they land on the way home.
    final place = leg.kind == TravelLegKind.arrival
        ? leg.from
        : leg.destination;
    final alias = place.aliasFor(locale).trim();
    final name = place.name.trim();
    final route = alias.isNotEmpty && name.isNotEmpty && alias != name
        ? '$alias - $name'
        : (name.isNotEmpty ? name : alias);

    // The ticketed departure wins over the published one: once a flight is
    // bought, its actual time is the one the participant has to be at the gate
    // for.
    final departsAt = result?.departsAt;
    final String when;
    if (departsAt != null) {
      when = DateFormat('dd.MM.yyyy - HH:mm').format(departsAt);
    } else {
      final day = DateFormat('dd.MM.yyyy').format(leg.date);
      when = leg.time == null ? day : '$day - ${leg.time}';
    }

    // Prefers the ticket, falls back to the flight that was requested.
    final service = leg.serviceLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppConfig.dividerNonOpaqueColor),
        const SizedBox(height: 16),
        Text(title, style: AppTextStyles.weGatherHeaderTextStyle),
        const SizedBox(height: 16),
        WgInfoRow(title: l10n.flights_routeLabel, information: _orDash(route, dash)),
        const SizedBox(height: 16),
        WgInfoRow(
          title: l10n.flights_flightRowLabel,
          information: _orDash(service, dash),
        ),
        const SizedBox(height: 16),
        WgInfoRow(title: l10n.flights_dateTimeLabel, information: when),
        // The PNR only exists once the ticket is bought, so the row appears with
        // the booking rather than sitting empty beforehand.
        if ((result?.reservationNumber ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          WgInfoRow(
            title: l10n.flights_pnrLabel,
            information: result!.reservationNumber!,
          ),
        ],
      ],
    );
  }
}

String _orDash(String? value, String dash) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? dash : trimmed;
}
