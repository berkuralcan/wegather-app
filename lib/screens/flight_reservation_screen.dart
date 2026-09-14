import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../config/text_styles.dart';
import '../l10n/app_localizations.dart';
import '../layouts/wegather_appbar.dart';
import '../models/external_transportation_model.dart';
import '../models/localized_text.dart';
import '../models/transportation_model.dart';
import '../providers/access_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/external_transportation_providers.dart';
import '../providers/profile_providers.dart';
import '../reusableWidgets/primary_button.dart';
import '../services/external_transportation_service.dart';
import '../transportation_widgets/destination_picker_sheet.dart';
import '../transportation_widgets/transfer_select_field.dart';
import '../travel_widgets/flight_picker_sheet.dart';
import '../travel_widgets/travel_preference_selector.dart';
import '../travel_widgets/travel_summary.dart';

/// The Flight Reservation module: how a participant is getting to the event
/// city, and home again.
///
/// This is the app's half of the panel's Travel section, and unlike the internal
/// transfers it is a request rather than a booking — the participant says what
/// they need, an admin buys the ticket outside the system, and the confirmed
/// flight comes back onto this screen. See
/// `models/external_transportation_model.dart` for the full shape.
///
/// What is on screen is decided entirely by the participant's own request:
///
///   * **no request yet** — the form: the travel preference, and (only when
///     flying) a city and a flight for each leg, then a review step and a
///     confirmation,
///   * **submitted, not yet ticketed** — what they asked for, under a notice
///     saying the details will appear once they are uploaded,
///   * **ticketed** — the same summary with the flight number and PNR filled in,
///     and no notice.
///
/// A submitted request stays editable, because the security rules allow exactly
/// that until the panel moves it off `submitted`. Once it moves, the screen
/// stops offering an edit it could not perform.
class FlightReservationScreen extends ConsumerStatefulWidget {
  const FlightReservationScreen({super.key});

  @override
  ConsumerState<FlightReservationScreen> createState() =>
      _FlightReservationScreenState();
}

/// Which part of the flow is on screen. [saved] is the resting state for a
/// request that already exists; the other three are the composing flow.
enum _Step { form, review, done, saved }

class _FlightReservationScreenState
    extends ConsumerState<FlightReservationScreen> {
  _Step? _step;

  TravelType? _preference;

  /// The city and flight chosen for each leg. A leg with a city but no flight is
  /// half-answered, which the review step refuses rather than silently drops.
  final Map<TravelLegKind, DestinationModel?> _cities = {
    TravelLegKind.arrival: null,
    TravelLegKind.departure: null,
  };
  final Map<TravelLegKind, FlightAvailability?> _flights = {
    TravelLegKind.arrival: null,
    TravelLegKind.departure: null,
  };

  bool _submitting = false;
  String? _formError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final request = ref.watch(myTravelRequestProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.flights_title,
        // Back steps within the flow before it leaves the screen, so a
        // participant reviewing their details can get back to the form.
        onBackPressed: _step == _Step.review ? _backToForm : null,
      ),
      body: SafeArea(
        top: false,
        child: request.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) => _Centered('${l10n.flights_loadError}\n\n$error'),
          data: (booking) {
            // The first build decides which state the screen opens in; after
            // that `_step` is the participant's own navigation and must win, or
            // submitting would bounce them straight back to the summary.
            _step ??= booking == null ? _Step.form : _Step.saved;
            return switch (_step!) {
              _Step.form => _buildForm(context, booking),
              _Step.review => _buildReview(context),
              _Step.done => _buildDone(context),
              _Step.saved => _buildSaved(context, booking),
            };
          },
        ),
      ),
    );
  }

  // --- The form -------------------------------------------------------------

  Widget _buildForm(
    BuildContext context,
    ExternalTransportationBookingModel? existing,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final options = ref.watch(flightOptionsProvider);

    return options.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, __) => _Centered('${l10n.flights_loadError}\n\n$error'),
      data: (flightOptions) {
        // Nothing published yet: the preference question alone would be a form
        // the participant cannot finish, so the module says so instead.
        if (flightOptions.isEmpty) return _Centered(l10n.flights_noFlights);
        // Seed the form from a request being edited, once the flights it refers
        // to are in hand — the pickers hold availabilities, not bare ids.
        _seedFrom(existing, flightOptions);

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.flights_preferenceTitle,
                          style: AppTextStyles.weGatherHeaderTextStyle,
                        ),
                        const SizedBox(height: 8),
                        TravelPreferenceSelector(
                          value: _preference,
                          selfLabel: l10n.flights_preferenceSelf,
                          flightLabel: l10n.flights_preferenceFlight,
                          onChanged: (value) => setState(() {
                            _preference = value;
                            _formError = null;
                          }),
                        ),
                        // Everything below the line is about a flight, so it
                        // only exists once one is being asked for.
                        if (_preference == TravelType.flight) ...[
                          const SizedBox(height: 16),
                          const Divider(
                            height: 1,
                            color: AppConfig.dividerNonOpaqueColor,
                          ),
                          _LegFields(
                            kind: TravelLegKind.arrival,
                            title: l10n.flights_arrivalSection,
                            cityLabel: l10n.flights_arrivalCityLabel,
                            city: _cities[TravelLegKind.arrival],
                            flight: _flights[TravelLegKind.arrival],
                            options: flightOptions,
                            onPickCity: () =>
                                _pickCity(TravelLegKind.arrival, flightOptions),
                            onPickFlight: () => _pickFlight(
                              TravelLegKind.arrival,
                              flightOptions,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(
                            height: 1,
                            color: AppConfig.dividerNonOpaqueColor,
                          ),
                          _LegFields(
                            kind: TravelLegKind.departure,
                            title: l10n.flights_departureSection,
                            cityLabel: l10n.flights_departureCityLabel,
                            city: _cities[TravelLegKind.departure],
                            flight: _flights[TravelLegKind.departure],
                            options: flightOptions,
                            onPickCity: () => _pickCity(
                              TravelLegKind.departure,
                              flightOptions,
                            ),
                            onPickFlight: () => _pickFlight(
                              TravelLegKind.departure,
                              flightOptions,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_formError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _formError!,
                      style: AppTextStyles.weGatherSmallTextStyle.copyWith(
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _BottomAction(
              label: l10n.flights_continue,
              onPressed: _preference == null ? null : _continueToReview,
            ),
          ],
        );
      },
    );
  }

  /// Fills the form from [existing] the first time it is built for an edit.
  ///
  /// Guarded on `_preference` rather than a flag because that is the one field
  /// the participant cannot leave unset once they have touched the form — so a
  /// null preference means nothing has been seeded or typed yet.
  void _seedFrom(
    ExternalTransportationBookingModel? existing,
    FlightOptions options,
  ) {
    if (existing == null || _preference != null) return;
    _preference = existing.type;
    for (final leg in existing.legs) {
      final match = options
          .flightsFor(leg.kind, FlightOptions.homeSideOf(_asFlight(leg)).id)
          .where((a) => a.transportation.id == leg.transportationId)
          .firstOrNull;
      // A flight that has since been withdrawn simply comes back unset, so the
      // participant re-picks rather than submitting a leg that no longer exists.
      if (match == null) continue;
      _cities[leg.kind] = FlightOptions.homeSideOf(match.transportation);
      _flights[leg.kind] = match;
    }
  }

  /// A saved leg viewed as the flight it was made against, so
  /// [FlightOptions.homeSideOf] can pick the participant's own end of it.
  ExternalTransportationModel _asFlight(ExternalTransportationLegModel leg) =>
      ExternalTransportationModel(
        id: leg.transportationId,
        kind: leg.kind,
        from: leg.from,
        destination: leg.destination,
        date: leg.date,
        time: leg.time,
      );

  Future<void> _pickCity(TravelLegKind kind, FlightOptions options) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDestinationPickerSheet(
      context,
      title: kind == TravelLegKind.arrival
          ? l10n.flights_arrivalCityLabel
          : l10n.flights_departureCityLabel,
      destinations: options.destinationsFor(kind),
      selected: _cities[kind],
    );
    if (picked == null || !mounted) return;
    setState(() {
      // Changing the city invalidates the flight chosen under the old one.
      if (_cities[kind]?.id != picked.id) _flights[kind] = null;
      _cities[kind] = picked;
      _formError = null;
    });
  }

  Future<void> _pickFlight(TravelLegKind kind, FlightOptions options) async {
    final l10n = AppLocalizations.of(context)!;
    final city = _cities[kind];
    if (city == null) return;

    final picked = await showFlightPickerSheet(
      context,
      title: l10n.flights_flightLabel,
      flights: options.flightsFor(kind, city.id),
      emptyLabel: l10n.flights_noFlightsForCity,
      fullLabel: l10n.flights_full,
      seatsLeftLabel: l10n.flights_seatsLeft,
      selected: _flights[kind],
    );
    if (picked == null || !mounted) return;
    setState(() {
      _flights[kind] = picked;
      _formError = null;
    });
  }

  void _continueToReview() {
    final l10n = AppLocalizations.of(context)!;
    if (_preference == TravelType.flight) {
      // A city with no flight under it is an unfinished answer, not an opt-out —
      // saying so beats quietly dropping the leg the participant thought they
      // had chosen.
      final halfAnswered = TravelLegKind.values.any(
        (kind) => _cities[kind] != null && _flights[kind] == null,
      );
      if (halfAnswered) {
        setState(() => _formError = l10n.flights_incompleteLeg);
        return;
      }
      if (_chosenFlights.isEmpty) {
        setState(() => _formError = l10n.flights_noLegChosen);
        return;
      }
    }
    setState(() {
      _formError = null;
      _step = _Step.review;
    });
  }

  void _backToForm() => setState(() => _step = _Step.form);

  List<ExternalTransportationModel> get _chosenFlights => [
    for (final kind in TravelLegKind.values)
      if (_flights[kind] != null) _flights[kind]!.transportation,
  ];

  // --- The review -----------------------------------------------------------

  Widget _buildReview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(
                l10n.flights_reviewIntro,
                textAlign: TextAlign.center,
                style: AppTextStyles.weGatherParagraphTextStyle,
              ),
              const SizedBox(height: 24),
              TravelSummary(
                passenger: _passengerFromProfile(),
                legs: _chosenFlights
                    .map(ExternalTransportationLegModel.fromTransportation)
                    .toList(),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _formError!,
                  style: AppTextStyles.weGatherSmallTextStyle.copyWith(
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),
        ),
        _BottomAction(
          label: l10n.flights_confirm,
          busy: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }

  /// The passenger as far as the app knows them today.
  ///
  /// Only the name comes from the profile — birth date, gender and identity
  /// numbers are not on it yet, so they go up absent and the review screen shows
  /// each as a dash. The request is still worth submitting without them: the
  /// panel needs to know who is flying where long before it needs a passport
  /// number, and the gaps are visible to both sides.
  TravelPassengerModel? _passengerFromProfile() {
    if (_preference != TravelType.flight) return null;
    final profile = ref.read(currentProfileProvider).valueOrNull;
    final email = profile?.email.trim();
    final phone = profile?.phone?.trim();
    return TravelPassengerModel(
      fullName: profile?.name.trim() ?? '',
      email: email == null || email.isEmpty ? null : email,
      phone: phone == null || phone.isEmpty ? null : phone,
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final eventId = ref.read(selectedEventIdProvider);
    final user = ref.read(currentUserProvider);
    final preference = _preference;
    if (eventId == null || user == null || preference == null) return;

    final profile = ref.read(currentProfileProvider).valueOrNull;
    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      await ref
          .read(externalTransportationServiceProvider)
          .submit(
            eventId: eventId,
            viewerId: user.uid,
            type: preference,
            passenger: _passengerFromProfile(),
            flights: _chosenFlights,
            // Denormalised so the panel's request list and its Excel export
            // need no roster join.
            viewerName: profile?.name,
            viewerEmail: profile?.email,
          );
      // Re-read rather than trusting what was sent: the seat counts have moved,
      // and the saved state must render what Firestore actually holds.
      ref.invalidate(myTravelRequestProvider);
      ref.invalidate(flightOptionsProvider);
      if (!mounted) return;
      setState(() => _step = _Step.done);
    } on FlightFullException {
      ref.invalidate(flightOptionsProvider);
      if (!mounted) return;
      // Back to the form: the message is about a field, so the field has to be
      // reachable to act on it.
      setState(() {
        _formError = l10n.flights_submitFull;
        _step = _Step.form;
      });
    } on StateError {
      ref.invalidate(myTravelRequestProvider);
      if (!mounted) return;
      setState(() {
        _formError = l10n.flights_lockedError;
        _step = _Step.saved;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = '${l10n.flights_submitError}\n$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // --- The confirmation -----------------------------------------------------

  Widget _buildDone(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/flight-confirmed.png'),
                  const SizedBox(height: 24),
                  Text(
                    l10n.flights_successTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.weGatherHeading1TextStyle,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.flights_successBody,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.weGatherParagraphTextStyle,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.flights_successHint,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.weGatherParagraphTextStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
        _BottomAction(
          label: l10n.flights_successAction,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  // --- A request that already exists ----------------------------------------

  Widget _buildSaved(
    BuildContext context,
    ExternalTransportationBookingModel? booking,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // The request was withdrawn out from under the screen (or never loaded);
    // falling back to the form is the only state that still makes sense.
    if (booking == null) return _buildForm(context, null);

    final isSelf = booking.type == TravelType.self;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              // The notice belongs only to the wait: once the tickets are in,
              // the flight details below it are the answer it was promising.
              if (!booking.isFulfilled) ...[
                _Notice(text: l10n.flights_pendingBanner),
                const SizedBox(height: 16),
              ],
              if (isSelf)
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.flights_savedSelfTitle,
                        style: AppTextStyles.weGatherHeaderTextStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.flights_savedSelfBody,
                        style: AppTextStyles.weGatherParagraphTextStyle,
                      ),
                    ],
                  ),
                )
              else
                TravelSummary(
                  passenger: booking.passenger,
                  legs: booking.legs,
                ),
            ],
          ),
        ),
        // Only while the panel has not taken the request over — the rules refuse
        // the write once it moves off `submitted`, so offering the button would
        // be offering a failure.
        if (booking.isEditable)
          _BottomAction(
            label: l10n.flights_edit,
            onPressed: () => setState(() {
              // Cleared so `_seedFrom` re-fills the form from the saved request.
              _preference = null;
              _cities[TravelLegKind.arrival] = null;
              _cities[TravelLegKind.departure] = null;
              _flights[TravelLegKind.arrival] = null;
              _flights[TravelLegKind.departure] = null;
              _formError = null;
              _step = _Step.form;
            }),
          ),
      ],
    );
  }
}

/// One leg's two fields: which city, and which flight from it. The flight field
/// stays disabled until a city is chosen, since the list it opens is the flights
/// from that city.
class _LegFields extends StatelessWidget {
  const _LegFields({
    required this.kind,
    required this.title,
    required this.cityLabel,
    required this.city,
    required this.flight,
    required this.options,
    required this.onPickCity,
    required this.onPickFlight,
  });

  final TravelLegKind kind;
  final String title;
  final String cityLabel;
  final DestinationModel? city;
  final FlightAvailability? flight;
  final FlightOptions options;
  final VoidCallback onPickCity;
  final VoidCallback onPickFlight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = WgLocale.fromJson(
      Localizations.localeOf(context).languageCode,
    );
    final chosen = flight?.transportation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: AppTextStyles.weGatherHeaderTextStyle),
        const SizedBox(height: 16),
        TransferSelectField(
          label: cityLabel,
          placeholder: l10n.flights_selectPlaceholder,
          value: city?.labelFor(locale),
          onTap: onPickCity,
        ),
        const SizedBox(height: 16),
        TransferSelectField(
          label: l10n.flights_flightLabel,
          placeholder: l10n.flights_selectPlaceholder,
          value: chosen == null ? null : _flightLabel(chosen, locale),
          onTap: city == null ? () {} : onPickFlight,
        ),
      ],
    );
  }

  /// What the closed field reads once a flight is chosen: the service when it is
  /// known, otherwise the route, so the field is never blank after a pick.
  String _flightLabel(ExternalTransportationModel flight, WgLocale locale) {
    final service = flight.serviceLabel;
    if (service.isNotEmpty) return service;
    return '${flight.from.labelFor(locale)} → '
        '${flight.destination.labelFor(locale)}';
  }
}

/// The card the form and the saved states are laid out on.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.tipColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConfig.loginPageFormBorderColor),
      ),
      child: child,
    );
  }
}

/// The "we have your preferences, the flights are coming" notice.
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConfig.loginPageFormBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConfig.emphasisColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppConfig.emphasisColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.weGatherSmallTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// The screen's single pinned action, sitting below the scrolling content the
/// way the mock's buttons do rather than scrolling away with it.
class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: busy
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              )
            : PrimaryButton(label: label, onPressed: onPressed),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered(this.text);

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
