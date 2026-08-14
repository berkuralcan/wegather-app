import 'package:cloud_firestore/cloud_firestore.dart';

import 'localized_text.dart';

/// The event schedule models, ported from the admin panel's `WGEventActivity` /
/// `WGEventParticipant` (`types/activities.ts`); keep the two in sync.
///
/// Two subcollections hang off an event:
///
///   * `events/{eventId}/participants/{participantId}` — the event's roster,
///   * `events/{eventId}/activities/{activityId}` — the scheduled activities.
///
/// An activity embeds a *snapshot* of each assigned participant (the whole
/// object, not just an id), so a row can be rendered without joining the
/// roster. The admin panel keeps those snapshots up to date.
///
/// Localised fields follow the app-wide convention (see [WgLocale]): bare when
/// the document is mono, `{tr, en}` when it is multilingual, with each document
/// carrying its own [ActivityModel.isMultilingual] flag so it is self-describing.
/// Language-agnostic fields — dates, a person's name, contact details, images —
/// are never localised.

/// A single scheduled activity.
///
/// [startDateTime] / [endDateTime] are absolute instants: an activity may span
/// more than one calendar day, so the end is stored in full rather than as a
/// duration (its length is derived, never persisted).
///
/// [titles] is always present; [locations], [locationDetails] and
/// [descriptions] are optional and null when the document omits them. As with
/// `EventModel` and `TipModel`, the plain getters read the primary (Turkish)
/// language — swap them for the `…For(locale)` variants once the app grows a
/// language switch.
class ActivityModel {
  final String id;
  final bool isMultilingual;
  final Map<WgLocale, String> titles;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final Map<WgLocale, String>? locations;
  final Map<WgLocale, String>? locationDetails;
  final Map<WgLocale, String>? descriptions;

  /// Embedded snapshots of the assigned roster participants.
  final List<ParticipantModel> participants;

  const ActivityModel({
    required this.id,
    required this.isMultilingual,
    required this.titles,
    required this.startDateTime,
    required this.endDateTime,
    this.locations,
    this.locationDetails,
    this.descriptions,
    this.participants = const [],
  });

  /// The title for [locale], falling back to the primary (Turkish) value.
  String titleFor(WgLocale locale) => localizedFor(titles, locale);

  /// The location for [locale] — empty when the activity has no location.
  String locationFor(WgLocale locale) =>
      locations == null ? '' : localizedFor(locations!, locale);

  /// The location detail for [locale] — empty when there is none.
  String locationDetailFor(WgLocale locale) =>
      locationDetails == null ? '' : localizedFor(locationDetails!, locale);

  /// The description for [locale] — empty when there is none.
  String descriptionFor(WgLocale locale) =>
      descriptions == null ? '' : localizedFor(descriptions!, locale);

  /// Primary-language title (Turkish).
  String get title => titleFor(WgLocale.tr);

  /// Primary-language location (Turkish), empty when unset.
  String get location => locationFor(WgLocale.tr);

  /// Primary-language location detail (Turkish), empty when unset.
  String get locationDetail => locationDetailFor(WgLocale.tr);

  /// Primary-language description (Turkish), empty when unset.
  String get description => descriptionFor(WgLocale.tr);

  /// Whether this activity overlaps [day] at all — true for every day of a
  /// multi-day activity, not just the one it starts on.
  bool touchesDay(DateTime day) {
    final dayStart = startOfDay(day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return startDateTime.isBefore(dayEnd) && endDateTime.isAfter(dayStart);
  }

  /// The calendar days this activity occupies, first to last.
  List<DateTime> get days => daysBetween(startDateTime, endDateTime);

  factory ActivityModel.fromJson(String id, Map<String, dynamic> json) {
    // Read the flag first: it decides how the localised fields are shaped.
    // Documents written before the flag existed are read off their payload.
    final isMultilingual =
        json['isMultilingual'] as bool? ?? isLocaleMap(json['title']);
    return ActivityModel(
      id: id,
      isMultilingual: isMultilingual,
      titles: parseLocalizedText(json['title'], isMultilingual),
      startDateTime: _toDate(json['startDateTime']),
      endDateTime: _toDate(json['endDateTime']),
      locations: _parseOptional(json['location'], isMultilingual),
      locationDetails: _parseOptional(json['locationDetail'], isMultilingual),
      descriptions: _parseOptional(json['description'], isMultilingual),
      participants: ((json['participants'] as List?) ?? const [])
          .map(
            (p) =>
                ParticipantModel.fromJson(Map<String, dynamic>.from(p as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'isMultilingual': isMultilingual,
    'title': localizedTextToJson(titles, isMultilingual),
    'startDateTime': Timestamp.fromDate(startDateTime),
    'endDateTime': Timestamp.fromDate(endDateTime),
    if (locations != null)
      'location': localizedTextToJson(locations!, isMultilingual),
    if (locationDetails != null)
      'locationDetail': localizedTextToJson(locationDetails!, isMultilingual),
    if (descriptions != null)
      'description': localizedTextToJson(descriptions!, isMultilingual),
    'participants': participants.map((p) => p.toJson()).toList(),
  };
}

/// A person in an event's roster ("added to the app").
///
/// [name] and [title] are the primary display fields; everything else is
/// optional profile detail. [cvUrls] is localised like the text fields because a
/// translated event wants a CV per language — the same file may be reused for
/// both, in which case the two locales simply hold the same URL.
class ParticipantModel {
  final String id;
  final bool isMultilingual;
  final String name;
  final Map<WgLocale, String> titles;
  final String? company;
  final String? email;
  final String? phone;
  final String? status;
  final Map<WgLocale, String>? descriptions;
  final Map<WgLocale, String>? cvUrls;
  final String? profileImage;
  final ParticipantSocials? socials;

  const ParticipantModel({
    required this.id,
    required this.isMultilingual,
    required this.name,
    required this.titles,
    this.company,
    this.email,
    this.phone,
    this.status,
    this.descriptions,
    this.cvUrls,
    this.profileImage,
    this.socials,
  });

  /// The title for [locale], falling back to the primary (Turkish) value.
  String titleFor(WgLocale locale) => localizedFor(titles, locale);

  /// The description for [locale] — empty when there is none.
  String descriptionFor(WgLocale locale) =>
      descriptions == null ? '' : localizedFor(descriptions!, locale);

  /// The CV URL for [locale] — empty when the participant has no CV.
  String cvUrlFor(WgLocale locale) =>
      cvUrls == null ? '' : localizedFor(cvUrls!, locale);

  /// Primary-language title (Turkish).
  String get title => titleFor(WgLocale.tr);

  /// Primary-language description (Turkish), empty when unset.
  String get description => descriptionFor(WgLocale.tr);

  /// Primary-language CV URL (Turkish), empty when unset.
  String get cvUrl => cvUrlFor(WgLocale.tr);

  /// Parse a participant from its own document, or from a copy embedded in an
  /// activity — [id] is then read out of the body, where the panel writes it.
  factory ParticipantModel.fromJson(Map<String, dynamic> json, {String? id}) {
    final isMultilingual =
        json['isMultilingual'] as bool? ?? isLocaleMap(json['title']);
    return ParticipantModel(
      id: id ?? json['id'] as String? ?? '',
      isMultilingual: isMultilingual,
      name: json['name'] as String? ?? '',
      titles: parseLocalizedText(json['title'], isMultilingual),
      company: json['company'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String?,
      descriptions: _parseOptional(json['description'], isMultilingual),
      cvUrls: _parseOptional(json['cvUrl'], isMultilingual),
      profileImage: json['profileImage'] as String?,
      socials: ParticipantSocials.fromJson(json['socials']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'isMultilingual': isMultilingual,
    'name': name,
    'title': localizedTextToJson(titles, isMultilingual),
    if (company != null) 'company': company,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (status != null) 'status': status,
    if (descriptions != null)
      'description': localizedTextToJson(descriptions!, isMultilingual),
    if (cvUrls != null) 'cvUrl': localizedTextToJson(cvUrls!, isMultilingual),
    if (profileImage != null) 'profileImage': profileImage,
    if (socials != null) 'socials': socials!.toJson(),
  };
}

/// A participant's social links (the panel's `WgEventParticipantSocials`).
///
/// The panel omits the whole map when every link is empty, so a participant
/// without links carries a null [ParticipantModel.socials] rather than an
/// object of nulls — "unset" stays visible, as with the localised fields.
class ParticipantSocials {
  final String? linkedin;
  final String? website;
  final String? portfolio;
  final String? instagram;

  const ParticipantSocials({
    this.linkedin,
    this.website,
    this.portfolio,
    this.instagram,
  });

  /// Parse the links map, dropping non-string entries. Returns null when the
  /// field is absent, malformed, or holds no link at all.
  static ParticipantSocials? fromJson(dynamic value) {
    if (value is! Map) return null;
    String? read(String key) {
      final link = value[key];
      return link is String && link.isNotEmpty ? link : null;
    }

    final socials = ParticipantSocials(
      linkedin: read('linkedin'),
      website: read('website'),
      portfolio: read('portfolio'),
      instagram: read('instagram'),
    );
    return socials.isEmpty ? null : socials;
  }

  /// Whether the participant has no link at all.
  bool get isEmpty =>
      linkedin == null &&
      website == null &&
      portfolio == null &&
      instagram == null;

  Map<String, dynamic> toJson() => {
    if (linkedin != null) 'linkedin': linkedin,
    if (website != null) 'website': website,
    if (portfolio != null) 'portfolio': portfolio,
    if (instagram != null) 'instagram': instagram,
  };
}

/// Parse a localised field that the panel omits when it is empty — null is kept
/// as null rather than becoming an empty locale map, so "unset" stays visible.
Map<WgLocale, String>? _parseOptional(dynamic value, bool isMultilingual) =>
    value == null ? null : parseLocalizedText(value, isMultilingual);

/// Accepts a [Timestamp], a [DateTime] or epoch millis so callers aren't
/// coupled to one representation (matches `EventModel` and the panel's `toDate`).
DateTime _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.fromMillisecondsSinceEpoch(0);
}

// ---------------------------------------------------------------------------
// Scheduling helpers — the Dart side of the panel's `startOfDay` / `isSameDay`
// / `daysBetween`. They work in local time, which is what the user sees.
// ---------------------------------------------------------------------------

/// Local midnight for [date] (the start of that calendar day).
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

/// Whether two instants fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) => startOfDay(a) == startOfDay(b);

/// Inclusive list of the calendar days spanned by `[start, end]`.
///
/// Days are stepped through the [DateTime] constructor rather than by adding 24
/// hours, so a DST change doesn't skip or duplicate one.
List<DateTime> daysBetween(DateTime start, DateTime end) {
  final last = startOfDay(end);
  var cursor = startOfDay(start);
  final days = <DateTime>[];
  while (!cursor.isAfter(last)) {
    days.add(cursor);
    cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
  }
  return days;
}
