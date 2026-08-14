import 'package:cloud_firestore/cloud_firestore.dart';

import 'localized_text.dart';

/// The transportation models, ported from the admin panel's
/// `types/transportation.ts`; keep the two in sync (see the two-repo note).
///
/// Events have two kinds of transportation. Only the **internal** side is
/// modelled here (getting between the hotel, the venue and the airport);
/// external transfers (reaching the event city from elsewhere) are not built
/// yet.
///
/// Transfers are created by admins in the panel. A user books one from the app
/// while it still has free seats (`capacity` minus the number of bookings). The
/// app filters them by picking a `from` + `destination`, then a date, then a
/// time.
///
/// Firestore layout — three subcollections hang off an event:
///
///   * `events/{eventId}/destinations/{destinationId}` — the managed places,
///   * `events/{eventId}/internalTransportations/{transportationId}` — transfers,
///   * `.../internalTransportations/{id}/bookings/{userId}` — one doc per booking,
///     **keyed by the booking user's uid** so a user holds at most one seat.
///
/// The app WRITES the booking docs (the panel only reads them for its
/// occupancy summary); everything else is written by the panel and read here.
///
/// Localisation: a destination's [name] is the real, language-agnostic name and
/// stays a plain string; its [aliases] (the short from/to-picker handle) is
/// localised and follows the app-wide "bare when mono, `{tr, en}` when
/// multilingual" convention (see [WgLocale]), with each destination carrying its
/// own [DestinationModel.isMultilingual] flag so it is self-describing — the
/// flag rides along in the embedded snapshots too.

/// A place a transfer runs to/from.
class DestinationModel {
  final String id;
  final bool isMultilingual;
  final String name;

  /// The localised alias, or null when the destination has none.
  final Map<WgLocale, String>? aliases;

  const DestinationModel({
    required this.id,
    required this.isMultilingual,
    required this.name,
    this.aliases,
  });

  /// The alias for [locale] — empty when the destination has no alias.
  String aliasFor(WgLocale locale) =>
      aliases == null ? '' : localizedFor(aliases!, locale);

  /// Primary-language alias (Turkish), empty when unset.
  String get alias => aliasFor(WgLocale.tr);

  /// A single label for display: the primary alias when set, else the name.
  String get label => alias.trim().isNotEmpty ? alias.trim() : name.trim();

  /// The label for [locale]: the alias in that language when set, else the name.
  String labelFor(WgLocale locale) {
    final a = aliasFor(locale).trim();
    return a.isNotEmpty ? a : name.trim();
  }

  /// Parse a destination from its own document, or from a copy embedded in a
  /// transfer — [id] is then read out of the body, where the panel writes it.
  factory DestinationModel.fromJson(Map<String, dynamic> json, {String? id}) {
    final isMultilingual =
        json['isMultilingual'] as bool? ?? isLocaleMap(json['alias']);
    return DestinationModel(
      id: id ?? json['id'] as String? ?? '',
      isMultilingual: isMultilingual,
      name: json['name'] as String? ?? '',
      // `alias` is pruned from the document when blank in every language, so a
      // missing value stays null rather than becoming an empty locale map.
      aliases: _parseOptional(json['alias'], isMultilingual),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'isMultilingual': isMultilingual,
    'name': name,
    if (aliases != null) 'alias': localizedTextToJson(aliases!, isMultilingual),
  };
}

/// A single scheduled internal transfer.
///
/// [from] / [destination] embed a snapshot of the chosen [DestinationModel] so
/// the app can render and filter without joining the destinations collection.
/// [date] is normalised to local midnight and [time] is an "HH:MM" string,
/// matching the app's two-step (pick a day, then a time) booking flow.
class InternalTransportationModel {
  final String id;
  final DestinationModel from;
  final DestinationModel destination;
  final DateTime date;
  final String time;
  final int capacity;

  const InternalTransportationModel({
    required this.id,
    required this.from,
    required this.destination,
    required this.date,
    required this.time,
    required this.capacity,
  });

  factory InternalTransportationModel.fromJson(
    String id,
    Map<String, dynamic> json,
  ) {
    return InternalTransportationModel(
      id: id,
      from: DestinationModel.fromJson(
        Map<String, dynamic>.from((json['from'] as Map?) ?? const {}),
      ),
      destination: DestinationModel.fromJson(
        Map<String, dynamic>.from((json['destination'] as Map?) ?? const {}),
      ),
      date: _startOfDay(_toDate(json['date'])),
      time: json['time'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'from': from.toJson(),
    'destination': destination.toJson(),
    'date': Timestamp.fromDate(_startOfDay(date)),
    'time': time,
    'capacity': capacity,
  };
}

/// A user's booking of a transfer, keyed by their uid.
///
/// [userName] is denormalised by the app at booking time so the panel can list
/// who is booked without joining the roster. [createdAt] is a server timestamp
/// set by the app. The app is the writer here; [toJson] documents the wire shape
/// (the app typically sets `createdAt` via `FieldValue.serverTimestamp()` on
/// write rather than passing a fixed instant).
class TransportationBookingModel {
  /// The booking user's uid (also the document id).
  final String userId;
  final String? userName;
  final DateTime? createdAt;

  const TransportationBookingModel({
    required this.userId,
    this.userName,
    this.createdAt,
  });

  factory TransportationBookingModel.fromJson(
    String userId,
    Map<String, dynamic> json,
  ) {
    return TransportationBookingModel(
      userId: userId.isNotEmpty ? userId : json['userId'] as String? ?? '',
      userName: json['userName'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    if (userName != null) 'userName': userName,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
  };
}

// ---------------------------------------------------------------------------
// Occupancy helpers — the Dart side of the panel's `availableSeats` / `isFull`
// / `bookedFraction`, for deciding whether a transfer can still be booked.
// ---------------------------------------------------------------------------

/// Seats still available (never negative, even if bookings exceed capacity).
int availableSeats(int capacity, int booked) =>
    (capacity - booked) < 0 ? 0 : capacity - booked;

/// Whether every seat on a transfer is taken.
bool isFull(int capacity, int booked) => booked >= capacity;

/// Booked share in `[0, 1]`, for a progress bar (0 when capacity is unset).
double bookedFraction(int capacity, int booked) {
  if (capacity <= 0) return 0;
  final fraction = booked / capacity;
  return fraction > 1 ? 1 : fraction;
}

/// Parse a localised field that the panel omits when it is empty — null is kept
/// as null rather than becoming an empty locale map, so "unset" stays visible.
Map<WgLocale, String>? _parseOptional(dynamic value, bool isMultilingual) =>
    value == null ? null : parseLocalizedText(value, isMultilingual);

/// Local midnight for [date] — transfers are filtered by calendar day.
DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

/// Accepts a [Timestamp], a [DateTime] or epoch millis so callers aren't coupled
/// to one representation (matches `ActivityModel` and the panel's `toDate`).
DateTime _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.fromMillisecondsSinceEpoch(0);
}
