import 'package:cloud_firestore/cloud_firestore.dart';

import 'transportation_model.dart';

/// The **external** transportation models — travel to the event city and home
/// again — ported from the admin panel's `types/transportation.ts`; keep the
/// two in sync (see the two-repo note).
///
/// External travel works nothing like the internal transfers in
/// `transportation_model.dart`, and the difference drives this whole file:
///
///   * Internal is a **seat pool**. Admins schedule a transfer with a capacity,
///     a user books a seat, and the booking either fits or it doesn't.
///   * External is a **request/fulfilment cycle**. Admins publish the flights
///     they intend to put people on; each user submits ONE request — either
///     "I'll make my own way" or a passenger record plus the flights they need;
///     admins buy the tickets outside the system and write each confirmed ticket
///     back onto the request; the app then shows it. A flight's [capacity] is
///     optional: absent means tickets get bought to match demand, a number means
///     a fixed block that can run out.
///
/// Firestore layout — under an event:
///
///   * `events/{eventId}/travelDestinations/{id}` — the origin cities and
///     airports. A **separate list** from the internal `destinations` (hotels
///     and venues in the event city) so neither pollutes the other's picker,
///     but the same shape, so [DestinationModel] is reused rather than cloned.
///   * `events/{eventId}/externalTransportations/{id}` — a published flight.
///   * `.../externalTransportations/{id}/seats/{uid}` — the countable mirror of
///     who is on a capacity-limited flight. It exists only because the request
///     document itself is readable by its owner and the event's managers alone
///     (it carries passport numbers), which leaves the app nothing to aggregate
///     when it needs to show "3 seats left". A seat carries no personal data
///     beyond the uid that is already its key, and reuses
///     [TransportationBookingModel].
///   * `events/{eventId}/externalTransportationBookings/{uid}` — the request.
///
/// The app writes the request and the seats; the panel writes `status` and each
/// leg's `result`. Both sides are covered by the rules in the panel's
/// `firestore.rules`.

/// Which half of the journey a flight covers, named from the event's point of
/// view: [arrival] gets a participant to the event city, [departure] takes them
/// home. Stored rather than derived so nothing has to know which destination is
/// the event's own city.
enum TravelLegKind {
  arrival('arrival'),
  departure('departure');

  const TravelLegKind(this.jsonValue);

  final String jsonValue;

  /// Anything unrecognised reads as an arrival — the same defaulting the
  /// panel's `toLegKind` does, so both sides agree on a malformed document.
  static TravelLegKind fromJson(dynamic value) => TravelLegKind.values
      .firstWhere((k) => k.jsonValue == value, orElse: () => arrival);
}

/// A flight admins have published for participants to request.
///
/// [carrier], [flightNumber] and [time] are optional on purpose: a flight may be
/// published as no more than "Istanbul → Antalya on 12 Oct" while the exact
/// service is still being negotiated. They are mandatory on
/// [ExternalTransportationResultModel], which records what was actually bought.
class ExternalTransportationModel {
  final String id;
  final TravelLegKind kind;
  final DestinationModel from;
  final DestinationModel destination;

  /// Local midnight — the travel day.
  final DateTime date;

  /// Scheduled departure as "HH:MM", or null while it is unknown.
  final String? time;
  final String? carrier;
  final String? flightNumber;

  /// Seats available when there is a fixed block; null means no limit. Read it
  /// through [seatsLeft] / [isFullAt] so the unlimited case stays in one place.
  final int? capacity;

  /// Anything participants should know when choosing ("via IST, 1 stop").
  final String? note;

  const ExternalTransportationModel({
    required this.id,
    required this.kind,
    required this.from,
    required this.destination,
    required this.date,
    this.time,
    this.carrier,
    this.flightNumber,
    this.capacity,
    this.note,
  });

  /// Whether this flight caps the number of people on it.
  bool get hasSeatLimit => capacity != null;

  /// Seats still free given [taken], or null when the flight has no limit.
  int? seatsLeft(int taken) {
    final limit = capacity;
    if (limit == null) return null;
    final left = limit - taken;
    return left < 0 ? 0 : left;
  }

  /// Whether a capacity-limited flight has run out. Unlimited is never full.
  bool isFullAt(int taken) => seatsLeft(taken) == 0;

  /// The airline and flight number as one label, empty while neither is known.
  String get serviceLabel =>
      [carrier, flightNumber].where((v) => v != null && v.isNotEmpty).join(' - ');

  factory ExternalTransportationModel.fromJson(
    String id,
    Map<String, dynamic> json,
  ) {
    // A stored 0 or negative means the same thing as an absent field: no limit.
    // Normalising on read keeps every caller off that edge case, and matches
    // the panel's own `externalTransportationFromJson`.
    final rawCapacity = (json['capacity'] as num?)?.toInt();
    return ExternalTransportationModel(
      id: id,
      kind: TravelLegKind.fromJson(json['kind']),
      from: DestinationModel.fromJson(
        Map<String, dynamic>.from((json['from'] as Map?) ?? const {}),
      ),
      destination: DestinationModel.fromJson(
        Map<String, dynamic>.from((json['destination'] as Map?) ?? const {}),
      ),
      date: _startOfDay(_toDate(json['date'])),
      time: _trimmedOrNull(json['time']),
      carrier: _trimmedOrNull(json['carrier']),
      flightNumber: _trimmedOrNull(json['flightNumber']),
      capacity: rawCapacity != null && rawCapacity > 0 ? rawCapacity : null,
      note: _trimmedOrNull(json['note']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.jsonValue,
    'from': from.toJson(),
    'destination': destination.toJson(),
    'date': Timestamp.fromDate(_startOfDay(date)),
    if (time != null) 'time': time,
    if (carrier != null) 'carrier': carrier,
    if (flightNumber != null) 'flightNumber': flightNumber,
    if (capacity != null) 'capacity': capacity,
    if (note != null) 'note': note,
  };
}

// ---------------------------------------------------------------------------
// The passenger
// ---------------------------------------------------------------------------

/// Airlines only accept a binary marker on a ticket, so this is the traveller's
/// **ticketing marker** rather than a profile field — never surface it as one.
enum TravelGender {
  male('male'),
  female('female');

  const TravelGender(this.jsonValue);

  final String jsonValue;

  /// Null for anything unset or unrecognised. Deliberately not defaulted: an
  /// unknown gender must read as unknown, or half the tickets get bought wrong.
  static TravelGender? fromJson(dynamic value) {
    for (final g in TravelGender.values) {
      if (g.jsonValue == value) return g;
    }
    return null;
  }
}

/// The document a ticket is issued against.
enum TravelDocumentType {
  passport('passport'),
  idCard('idCard'),
  other('other');

  const TravelDocumentType(this.jsonValue);

  final String jsonValue;

  static TravelDocumentType? fromJson(dynamic value) {
    for (final t in TravelDocumentType.values) {
      if (t.jsonValue == value) return t;
    }
    return null;
  }
}

/// The traveller, exactly as the ticket must be issued.
///
/// Everything but [fullName] is optional, and that is deliberate rather than
/// lax: the app builds this from the user's profile, which today carries a name
/// and little else, so a request is submitted with the ticketing fields blank
/// and the review screen renders each gap as a dash. A ticket cannot be bought
/// from a partial record — [isTicketable] is what says so — but a request can
/// certainly be made from one.
class TravelPassengerModel {
  /// As printed on the travel document, not the display name.
  final String fullName;

  /// Local midnight — a birth date has no time component.
  final DateTime? birthDate;
  final TravelGender? gender;
  final String? nationality;
  final TravelDocumentType? documentType;

  /// The number printed on the document named by [documentType] — so a passport
  /// number is just this with [TravelDocumentType.passport].
  final String? documentNumber;

  /// Only TR ID cards carry one; absent on passports.
  final String? documentSerialNumber;
  final DateTime? documentExpiresAt;
  final String? phone;
  final String? email;

  const TravelPassengerModel({
    required this.fullName,
    this.birthDate,
    this.gender,
    this.nationality,
    this.documentType,
    this.documentNumber,
    this.documentSerialNumber,
    this.documentExpiresAt,
    this.phone,
    this.email,
  });

  /// Whether this carries enough for a ticket to actually be issued. The panel
  /// gates its results table on the same check.
  bool get isTicketable =>
      fullName.trim().isNotEmpty &&
      birthDate != null &&
      gender != null &&
      documentType != null &&
      (documentNumber?.trim().isNotEmpty ?? false);

  TravelPassengerModel copyWith({
    String? fullName,
    DateTime? birthDate,
    TravelGender? gender,
    String? nationality,
    TravelDocumentType? documentType,
    String? documentNumber,
    String? documentSerialNumber,
    DateTime? documentExpiresAt,
    String? phone,
    String? email,
  }) => TravelPassengerModel(
    fullName: fullName ?? this.fullName,
    birthDate: birthDate ?? this.birthDate,
    gender: gender ?? this.gender,
    nationality: nationality ?? this.nationality,
    documentType: documentType ?? this.documentType,
    documentNumber: documentNumber ?? this.documentNumber,
    documentSerialNumber: documentSerialNumber ?? this.documentSerialNumber,
    documentExpiresAt: documentExpiresAt ?? this.documentExpiresAt,
    phone: phone ?? this.phone,
    email: email ?? this.email,
  );

  factory TravelPassengerModel.fromJson(Map<String, dynamic> json) {
    final birthDate = _toDateOrNull(json['birthDate']);
    return TravelPassengerModel(
      fullName: json['fullName'] as String? ?? '',
      birthDate: birthDate == null ? null : _startOfDay(birthDate),
      gender: TravelGender.fromJson(json['gender']),
      nationality: _trimmedOrNull(json['nationality']),
      documentType: TravelDocumentType.fromJson(json['documentType']),
      documentNumber: _trimmedOrNull(json['documentNumber']),
      documentSerialNumber: _trimmedOrNull(json['documentSerialNumber']),
      documentExpiresAt: _toDateOrNull(json['documentExpiresAt']),
      phone: _trimmedOrNull(json['phone']),
      email: _trimmedOrNull(json['email']),
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName.trim(),
    if (birthDate != null)
      'birthDate': Timestamp.fromDate(_startOfDay(birthDate!)),
    if (gender != null) 'gender': gender!.jsonValue,
    if (nationality != null) 'nationality': nationality,
    if (documentType != null) 'documentType': documentType!.jsonValue,
    if (documentNumber != null) 'documentNumber': documentNumber,
    if (documentSerialNumber != null)
      'documentSerialNumber': documentSerialNumber,
    if (documentExpiresAt != null)
      'documentExpiresAt': Timestamp.fromDate(documentExpiresAt!),
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
  };
}

// ---------------------------------------------------------------------------
// The confirmed ticket
// ---------------------------------------------------------------------------

/// What was actually booked for one requested leg — written by an admin from
/// the panel once the tickets are bought, and read here to show the user their
/// flight number and PNR.
///
/// Deliberately not a subclass of [ExternalTransportationModel]: a flight option
/// is what a participant may ask for, a result is what they got, and the two
/// only look alike.
class ExternalTransportationResultModel {
  final String carrier;
  final String flightNumber;

  /// PNR / booking reference the passenger checks in with.
  final String? reservationNumber;
  final String? ticketNumber;

  /// The ticketed times, which may differ from the published flight's.
  final DateTime? departsAt;
  final DateTime? arrivesAt;
  final String? seat;
  final String? baggageAllowance;
  final String? note;
  final DateTime? confirmedAt;

  const ExternalTransportationResultModel({
    required this.carrier,
    required this.flightNumber,
    this.reservationNumber,
    this.ticketNumber,
    this.departsAt,
    this.arrivesAt,
    this.seat,
    this.baggageAllowance,
    this.note,
    this.confirmedAt,
  });

  /// A result is usable only once the two ticketing essentials are filled in —
  /// the panel can save a half-typed row, and this is what stops the app
  /// presenting one as a confirmed flight.
  bool get isComplete =>
      carrier.trim().isNotEmpty && flightNumber.trim().isNotEmpty;

  /// The airline and flight number as one label, as the ticket reads.
  String get serviceLabel => '${carrier.trim()} - ${flightNumber.trim()}';

  factory ExternalTransportationResultModel.fromJson(
    Map<String, dynamic> json,
  ) => ExternalTransportationResultModel(
    carrier: json['carrier'] as String? ?? '',
    flightNumber: json['flightNumber'] as String? ?? '',
    reservationNumber: _trimmedOrNull(json['reservationNumber']),
    ticketNumber: _trimmedOrNull(json['ticketNumber']),
    departsAt: _toDateOrNull(json['departsAt']),
    arrivesAt: _toDateOrNull(json['arrivesAt']),
    seat: _trimmedOrNull(json['seat']),
    baggageAllowance: _trimmedOrNull(json['baggageAllowance']),
    note: _trimmedOrNull(json['note']),
    confirmedAt: _toDateOrNull(json['confirmedAt']),
  );

  Map<String, dynamic> toJson() => {
    'carrier': carrier.trim(),
    'flightNumber': flightNumber.trim(),
    if (reservationNumber != null) 'reservationNumber': reservationNumber,
    if (ticketNumber != null) 'ticketNumber': ticketNumber,
    if (departsAt != null) 'departsAt': Timestamp.fromDate(departsAt!),
    if (arrivesAt != null) 'arrivesAt': Timestamp.fromDate(arrivesAt!),
    if (seat != null) 'seat': seat,
    if (baggageAllowance != null) 'baggageAllowance': baggageAllowance,
    if (note != null) 'note': note,
    'confirmedAt': confirmedAt == null
        ? null
        : Timestamp.fromDate(confirmedAt!),
  };
}

// ---------------------------------------------------------------------------
// A requested leg
// ---------------------------------------------------------------------------

/// One flight a user asked for, plus the ticket they ended up with.
///
/// [from] / [destination] / [date] are snapshots of the chosen flight — the same
/// convention internal transfers use — so a request stays readable even after
/// the flight it was made against is edited or withdrawn.
class ExternalTransportationLegModel {
  /// The [ExternalTransportationModel] the user chose.
  final String transportationId;
  final TravelLegKind kind;
  final DestinationModel from;
  final DestinationModel destination;
  final DateTime date;
  final String? time;

  /// The service as it was published, snapshotted alongside the route. Carried
  /// here — rather than looked up from the flight — so a request still shows the
  /// flight the participant asked for in the window between submitting and being
  /// ticketed, and still shows it if an admin edits the published flight
  /// afterwards. Both stay null while the flight is still being arranged.
  final String? carrier;
  final String? flightNumber;

  /// Filled in by an admin once the ticket is bought.
  final ExternalTransportationResultModel? result;

  const ExternalTransportationLegModel({
    required this.transportationId,
    required this.kind,
    required this.from,
    required this.destination,
    required this.date,
    this.time,
    this.carrier,
    this.flightNumber,
    this.result,
  });

  /// Whether this leg has a ticket the user can actually travel on.
  bool get isTicketed => result?.isComplete ?? false;

  /// The service to show for this leg: what was ticketed once it exists, else
  /// what was requested. Empty when neither is known yet, which the review
  /// screen renders as a dash.
  String get serviceLabel {
    final ticket = result;
    if (ticket != null && ticket.isComplete) return ticket.serviceLabel;
    return [
      carrier,
      flightNumber,
    ].where((v) => v != null && v.isNotEmpty).join(' - ');
  }

  /// Built from the flight the user picked; the result lands later.
  factory ExternalTransportationLegModel.fromTransportation(
    ExternalTransportationModel transportation,
  ) => ExternalTransportationLegModel(
    transportationId: transportation.id,
    kind: transportation.kind,
    from: transportation.from,
    destination: transportation.destination,
    date: transportation.date,
    time: transportation.time,
    carrier: transportation.carrier,
    flightNumber: transportation.flightNumber,
  );

  factory ExternalTransportationLegModel.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    return ExternalTransportationLegModel(
      transportationId: json['transportationId'] as String? ?? '',
      kind: TravelLegKind.fromJson(json['kind']),
      from: DestinationModel.fromJson(
        Map<String, dynamic>.from((json['from'] as Map?) ?? const {}),
      ),
      destination: DestinationModel.fromJson(
        Map<String, dynamic>.from((json['destination'] as Map?) ?? const {}),
      ),
      date: _startOfDay(_toDate(json['date'])),
      time: _trimmedOrNull(json['time']),
      carrier: _trimmedOrNull(json['carrier']),
      flightNumber: _trimmedOrNull(json['flightNumber']),
      result: result is Map
          ? ExternalTransportationResultModel.fromJson(
              Map<String, dynamic>.from(result),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'transportationId': transportationId,
    'kind': kind.jsonValue,
    'from': from.toJson(),
    'destination': destination.toJson(),
    'date': Timestamp.fromDate(_startOfDay(date)),
    if (time != null) 'time': time,
    if (carrier != null) 'carrier': carrier,
    if (flightNumber != null) 'flightNumber': flightNumber,
    if (result != null) 'result': result!.toJson(),
  };
}

// ---------------------------------------------------------------------------
// The request
// ---------------------------------------------------------------------------

/// How a participant is getting to the event. [self] means they are making their
/// own way and want nothing booked — still recorded, so admins can tell "not
/// travelling with us" apart from "hasn't answered yet".
enum TravelType {
  flight('flight'),
  self('self');

  const TravelType(this.jsonValue);

  final String jsonValue;

  static TravelType fromJson(dynamic value) =>
      value == 'self' ? TravelType.self : TravelType.flight;
}

/// Where a request stands. The app writes [submitted]; the panel moves it to
/// [booked] once every leg has a ticket, and [cancelled] when someone drops out.
enum TravelStatus {
  submitted('submitted'),
  booked('booked'),
  cancelled('cancelled');

  const TravelStatus(this.jsonValue);

  final String jsonValue;

  static TravelStatus fromJson(dynamic value) => TravelStatus.values
      .firstWhere((s) => s.jsonValue == value, orElse: () => submitted);
}

/// A participant's travel request — one document per user, keyed by their uid.
///
/// Passenger details live here once rather than on each leg: a request covers
/// one person, and duplicating a passport number per flight is how the two
/// copies drift apart. The app writes [type], [passenger], [legs] (without
/// results) and [notes]; the panel writes [status], `adminNote` and each leg's
/// result — which is why a user may only edit their own request while it is
/// still [TravelStatus.submitted].
class ExternalTransportationBookingModel {
  /// The requesting user's uid (also the document id).
  final String userId;
  final String? userName;
  final String? userEmail;
  final TravelType type;

  /// Null when [type] is [TravelType.self] — nothing is being ticketed.
  final TravelPassengerModel? passenger;

  /// Empty when [type] is [TravelType.self].
  final List<ExternalTransportationLegModel> legs;
  final TravelStatus status;

  /// From the participant ("I'd prefer a morning flight").
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExternalTransportationBookingModel({
    required this.userId,
    this.userName,
    this.userEmail,
    required this.type,
    this.passenger,
    this.legs = const [],
    this.status = TravelStatus.submitted,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Whether the user may still change this. Once the panel has moved it off
  /// `submitted` the request is the organiser's, and security rules refuse the
  /// write anyway — so the screen must not offer an edit it cannot perform.
  bool get isEditable => status == TravelStatus.submitted;

  /// Every leg of a flight request has a usable ticket.
  bool get isFulfilled {
    if (type == TravelType.self) return true;
    return legs.isNotEmpty && legs.every((leg) => leg.isTicketed);
  }

  /// The legs of one half of the journey, earliest first.
  List<ExternalTransportationLegModel> legsOfKind(TravelLegKind kind) =>
      legs.where((leg) => leg.kind == kind).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  /// The ids of the flights this request is on — what the seat mirror is keyed
  /// against when a request is edited.
  Set<String> get transportationIds =>
      legs.map((leg) => leg.transportationId).where((id) => id.isNotEmpty).toSet();

  factory ExternalTransportationBookingModel.fromJson(
    String userId,
    Map<String, dynamic> json,
  ) {
    final type = TravelType.fromJson(json['type']);
    final passenger = json['passenger'];
    return ExternalTransportationBookingModel(
      userId: userId.isNotEmpty ? userId : json['userId'] as String? ?? '',
      userName: _trimmedOrNull(json['userName']),
      userEmail: _trimmedOrNull(json['userEmail']),
      type: type,
      // A `self` request has nothing to ticket, so ignore any stale passenger
      // block left behind by someone who switched away from flying.
      passenger: type == TravelType.flight && passenger is Map
          ? TravelPassengerModel.fromJson(Map<String, dynamic>.from(passenger))
          : null,
      legs: type == TravelType.flight
          ? ((json['legs'] as List?) ?? const [])
                .whereType<Map>()
                .map(
                  (leg) => ExternalTransportationLegModel.fromJson(
                    Map<String, dynamic>.from(leg),
                  ),
                )
                .toList()
          : const [],
      status: TravelStatus.fromJson(json['status']),
      notes: _trimmedOrNull(json['notes']),
      createdAt: _toDateOrNull(json['createdAt']),
      updatedAt: _toDateOrNull(json['updatedAt']),
    );
  }

  /// The wire shape the app writes.
  ///
  /// `adminNote` and each leg's `result` are absent by construction — they are
  /// the panel's fields, and the rules reject a participant touching the first.
  /// `createdAt` / `updatedAt` are set by the repository with the server clock
  /// rather than the device's.
  Map<String, dynamic> toJson() => {
    'userId': userId,
    if (userName != null) 'userName': userName,
    if (userEmail != null) 'userEmail': userEmail,
    'type': type.jsonValue,
    if (type == TravelType.flight && passenger != null)
      'passenger': passenger!.toJson(),
    'legs': type == TravelType.flight
        ? legs.map((leg) => leg.toJson()).toList()
        : const <Map<String, dynamic>>[],
    'status': status.jsonValue,
    if (notes != null) 'notes': notes,
  };
}

// ---------------------------------------------------------------------------
// Parsing helpers — the same shapes `transportation_model.dart` uses, kept
// private here so the two files stay independently readable.
// ---------------------------------------------------------------------------

String? _trimmedOrNull(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _toDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}
