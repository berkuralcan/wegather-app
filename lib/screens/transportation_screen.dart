import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../models/localized_text.dart';
import '../models/transportation_model.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/transportation_providers.dart';
import '../reusableWidgets/liquid_snackbar.dart';
import '../reusableWidgets/primary_button.dart';
import '../services/transportation_service.dart';
import '../transportation_widgets/destination_picker_sheet.dart';
import '../transportation_widgets/transfer_card.dart';
import '../transportation_widgets/transfer_select_field.dart';

/// The Transportation module: find the event's transfers between two places on
/// a day, and take a seat on one.
///
/// The screen opens as the search form alone — an origin, a destination and a
/// date, none of them filled in — and the search button stays disabled until all
/// three are. Submitting reveals the matching departures underneath; the form
/// stays put so the user can search again.
///
/// The module is read-only apart from the seat button on a result: the transfers
/// themselves are authored in the admin panel, and the only thing the app writes
/// is the user's own booking (see [TransportationService]).
class TransportationScreen extends ConsumerStatefulWidget {
  const TransportationScreen({super.key});

  @override
  ConsumerState<TransportationScreen> createState() =>
      _TransportationScreenState();
}

class _TransportationScreenState extends ConsumerState<TransportationScreen> {
  DestinationModel? _from;
  DestinationModel? _destination;
  DateTime? _day;

  /// The last search that was actually submitted — null until the button is
  /// pressed, which is what keeps the results section hidden on first open.
  /// Editing a field afterwards leaves the previous results up until the user
  /// searches again, so nothing disappears under their finger.
  TransferQuery? _query;

  /// The transfer whose booking is in flight, so only its own button spins.
  String? _bookingTransferId;

  bool get _canSearch => _from != null && _destination != null && _day != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = ref.watch(destinationsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.transportation_title),
      body: SafeArea(
        top: false,
        child: destinations.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) =>
              _CenteredText('${l10n.transportation_loadError}\n\n$error'),
          data: (list) {
            if (list.isEmpty) {
              return _CenteredText(l10n.transportation_noDestinations);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _SearchCard(
                  from: _from,
                  destination: _destination,
                  day: _day,
                  onPickFrom: () => _pickDestination(isOrigin: true),
                  onPickDestination: () => _pickDestination(isOrigin: false),
                  onPickDay: _pickDay,
                  onSearch: _canSearch ? _search : null,
                ),
                if (_query != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.transportation_resultsTitle,
                    style: AppTextStyles.weGatherLabelTextStyle,
                  ),
                  const SizedBox(height: 12),
                  _Results(
                    query: _query!,
                    bookingTransferId: _bookingTransferId,
                    onBook: _book,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Opens the picker for one end of the journey. The other end is excluded, so
  /// a transfer can't be searched from a place to itself.
  Future<void> _pickDestination({required bool isOrigin}) async {
    final l10n = AppLocalizations.of(context)!;
    final destinations = ref.read(destinationsProvider).valueOrNull ?? const [];

    final picked = await showDestinationPickerSheet(
      context,
      title: isOrigin
          ? l10n.transportation_fromLabel
          : l10n.transportation_toLabel,
      destinations: destinations,
      selected: isOrigin ? _from : _destination,
      excluded: isOrigin ? _destination : _from,
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isOrigin) {
        _from = picked;
      } else {
        _destination = picked;
      }
    });
  }

  /// Opens the calendar over the days a transfer could run.
  ///
  /// The window is the event's own dates widened to its active window — the
  /// period it is live on the platform — because the transfers that matter most
  /// are the airport runs on the way in and out, which sit at the edges of the
  /// event rather than inside it. Picking a day with nothing on it simply
  /// returns no results.
  Future<void> _pickDay() async {
    final event = ref.read(selectedEventProvider).valueOrNull;
    final today = DateTime.now();
    final first = event == null
        ? DateTime(today.year - 1)
        : _earlier(event.eventStartDate, event.eventActiveStartDate);
    final end = event == null
        ? DateTime(today.year + 1)
        : _later(event.eventEndDate, event.eventActiveEndDate);
    // An event whose end somehow precedes its start would leave the picker with
    // an empty range, so the window never closes on itself.
    final last = end.isBefore(first) ? first : end;
    final initial = _clamp(_day ?? today, first, last);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      // The app runs light-themed widgets over a dark gradient, so the calendar
      // has to be told to be dark — it would otherwise open as a white sheet.
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppConfig.emphasisColor,
            surface: Color(0xFF09245D),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    // Transfers are stored at local midnight, so the selection is normalised to
    // the calendar day before it ever reaches a query.
    setState(() => _day = DateTime(picked.year, picked.month, picked.day));
  }

  /// [date] brought inside the picker's window, so an out-of-range default (a
  /// today outside the event) still opens on a valid day.
  DateTime _clamp(DateTime date, DateTime first, DateTime last) {
    if (date.isBefore(first)) return first;
    if (date.isAfter(last)) return last;
    return date;
  }

  DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  void _search() {
    setState(() {
      _query = TransferQuery(
        fromId: _from!.id,
        destinationId: _destination!.id,
        day: _day!,
      );
    });
  }

  /// Takes a seat on [availability] for the signed-in user.
  ///
  /// The result list is invalidated either way: on success it re-renders the row
  /// as booked, and when the transfer filled up in the meantime it re-renders it
  /// as full — which is the honest thing to show alongside the message.
  Future<void> _book(TransferAvailability availability) async {
    final l10n = AppLocalizations.of(context)!;
    final eventId = ref.read(selectedEventIdProvider);
    final user = ref.read(currentUserProvider);
    final query = _query;
    if (eventId == null || user == null || query == null) return;

    setState(() => _bookingTransferId = availability.transportation.id);
    try {
      await ref
          .read(transportationServiceProvider)
          .book(
            eventId: eventId,
            transfer: availability.transportation,
            viewerId: user.uid,
            // Denormalised so the panel's passenger list needs no roster join.
            viewerName: ref.read(currentProfileProvider).valueOrNull?.name,
          );
      ref.invalidate(transferSearchProvider(query));
      if (!mounted) return;
      showLiquidSnackBar(
        context,
        l10n.transportation_bookSuccess,
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    } on TransferFullException {
      ref.invalidate(transferSearchProvider(query));
      if (!mounted) return;
      showLiquidSnackBar(
        context,
        l10n.transportation_bookFull,
        icon: Icons.error,
        iconColor: Colors.red,
      );
    } catch (error) {
      if (!mounted) return;
      showLiquidSnackBar(
        context,
        '${l10n.transportation_bookError}\n$error',
        icon: Icons.error,
        iconColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _bookingTransferId = null);
    }
  }
}

/// The search form: where from, where to, which day, and the button that runs
/// it — disabled until all three are answered.
class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.from,
    required this.destination,
    required this.day,
    required this.onPickFrom,
    required this.onPickDestination,
    required this.onPickDay,
    required this.onSearch,
  });

  final DestinationModel? from;
  final DestinationModel? destination;
  final DateTime? day;
  final VoidCallback onPickFrom;
  final VoidCallback onPickDestination;
  final VoidCallback onPickDay;

  /// Null while the form is incomplete, which renders the button as disabled.
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = WgLocale.fromJson(
      Localizations.localeOf(context).languageCode,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.tipColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConfig.loginPageFormBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TransferSelectField(
                  label: l10n.transportation_fromLabel,
                  placeholder: l10n.transportation_selectPlaceholder,
                  value: from?.labelFor(locale),
                  onTap: onPickFrom,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TransferSelectField(
                  label: l10n.transportation_toLabel,
                  placeholder: l10n.transportation_selectPlaceholder,
                  value: destination?.labelFor(locale),
                  onTap: onPickDestination,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TransferSelectField(
            label: l10n.transportation_dateLabel,
            placeholder: l10n.transportation_selectPlaceholder,
            value: day == null ? null : DateFormat('dd/MM/yyyy').format(day!),
            leadingIcon: Icons.calendar_today_outlined,
            trailingIcon: null,
            onTap: onPickDay,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: l10n.transportation_search,
              onPressed: onSearch,
            ),
          ),
        ],
      ),
    );
  }
}

/// The departures matching the submitted search.
class _Results extends ConsumerWidget {
  const _Results({
    required this.query,
    required this.bookingTransferId,
    required this.onBook,
  });

  final TransferQuery query;
  final String? bookingTransferId;
  final void Function(TransferAvailability) onBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final results = ref.watch(transferSearchProvider(query));

    return results.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, __) =>
          _CenteredText('${l10n.transportation_loadError}\n\n$error'),
      data: (list) {
        if (list.isEmpty) return _CenteredText(l10n.transportation_noResults);
        return Column(
          children: [
            for (final (index, availability) in list.indexed) ...[
              if (index > 0) const SizedBox(height: 12),
              TransferCard(
                availability: availability,
                isBooking: bookingTransferId == availability.transportation.id,
                onBook: () => onBook(availability),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CenteredText extends StatelessWidget {
  const _CenteredText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.weGatherParagraphTextStyle,
        ),
      ),
    );
  }
}
