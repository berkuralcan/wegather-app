import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../services/transportation_service.dart';

/// One transfer in the search results: when it leaves, where from, and the one
/// thing the user can do about it.
///
/// Everything on the card is read-only except the seat button, which appears
/// only while the transfer has room. A full transfer says so instead, and a
/// transfer the user is already on shows that they hold a seat rather than
/// offering them a second one.
class TransferCard extends StatelessWidget {
  const TransferCard({
    super.key,
    required this.availability,
    required this.onBook,
    this.isBooking = false,
  });

  final TransferAvailability availability;

  /// Takes a seat. Only ever reachable while [TransferAvailability.canBook].
  final VoidCallback onBook;

  /// Whether this card's booking is in flight — the button shows a spinner and
  /// stops accepting taps.
  final bool isBooking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transfer = availability.transportation;
    // The departure day and time as one line, e.g. "15/03/2025 - 10:00". `time`
    // is already an "HH:MM" string, so only the date needs formatting.
    final departure =
        '${DateFormat('dd/MM/yyyy').format(transfer.date)} - ${transfer.time}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppConfig.tipColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConfig.loginPageFormBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(departure, style: AppTextStyles.weGatherLabelTextStyle),
                const SizedBox(height: 4),
                // The pick-up point: the origin's real name rather than the
                // short handle the search was made with.
                Text(
                  transfer.from.name,
                  style: AppTextStyles.weGatherSmallTextStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (availability.isBookedByViewer)
            const _SeatChip(state: _SeatState.booked)
          else if (availability.isFullyBooked)
            const _SeatChip(state: _SeatState.full)
          else
            _BookButton(
              label: l10n.transportation_choose,
              onPressed: isBooking ? null : onBook,
              isBusy: isBooking,
            ),
        ],
      ),
    );
  }
}

/// What a non-actionable seat state says.
enum _SeatState { booked, full }

/// The flat counterpart of [_BookButton]: says what the state of the seat is
/// when there is nothing to tap — the transfer is full, or already booked.
class _SeatChip extends StatelessWidget {
  const _SeatChip({required this.state});

  final _SeatState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isBooked = state == _SeatState.booked;

    return Container(
      height: 32,
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // A booked seat is the user's own state, so it keeps the accent fill;
        // a full transfer is simply unavailable and stays neutral.
        gradient: isBooked ? AppConfig.activeButtonFillGradient : null,
        color: isBooked ? null : AppConfig.primaryFillColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isBooked ? l10n.transportation_booked : l10n.transportation_full,
        style: AppTextStyles.weGatherTabTextStyle.copyWith(
          color: isBooked
              ? AppConfig.labelTextColor
              : AppConfig.secondaryTextColor,
        ),
      ),
    );
  }
}

/// The seat button — the one interactive control in the module.
class _BookButton extends StatelessWidget {
  const _BookButton({
    required this.label,
    required this.onPressed,
    required this.isBusy,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppConfig.buttonPrimaryGradient,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Container(
            height: 32,
            constraints: const BoxConstraints(minWidth: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: AppTextStyles.weGatherTabTextStyle.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
