import 'package:cloud_firestore/cloud_firestore.dart';

import 'localized_text.dart';

/// An event — the unit everything else in the app hangs off. Ported from the
/// admin panel's `WGEvent` (`types/events.ts`); keep the two in sync.
///
/// Dates:
///   * [eventStartDate] / [eventEndDate] are the real-world dates of the event.
///     There is no `isOneDay` flag because it can be inferred.
///   * [eventActiveStartDate] / [eventActiveEndDate] are the window the event
///     is live on the platform: managers can create content from the start
///     date, and the end date is the last day users may sign in.
///
/// [titles] / [descriptions] carry a value per [WgLocale] on a multilingual
/// event; a mono event stores a single, language-agnostic value under
/// [WgLocale.tr]. The [title]/[description] getters default to the primary
/// (Turkish) language so existing screens keep working — swap them for
/// [titleFor]/[descriptionFor] once the app adds a language switch (the same
/// arrangement [TipModel] uses).
///
/// [eventSlogans] and [eventFeaturedImages] are localised the same way. The
/// featured image is localised because a multilingual event may use a different
/// hero image per language (e.g. one baked with Turkish copy, one with English),
/// not just a translated caption. [eventLogo] stays a single, language-agnostic
/// image. [eventSlogan] is optional (pruned from the document when blank in every
/// language), so a missing value simply reads back as empty strings.
class EventModel {
  final String id;
  final Map<WgLocale, String> titles;
  final Map<WgLocale, String> descriptions;

  /// -> `companies/{companyId}`.
  final String companyId;
  final String eventLogo;

  /// Localised hero image: one URL per language on a multilingual event.
  final Map<WgLocale, String> eventFeaturedImages;

  /// Localised, optional tagline. Blank in every language when unset.
  final Map<WgLocale, String> eventSlogans;
  final DateTime eventStartDate;
  final DateTime eventEndDate;
  final DateTime eventActiveStartDate;
  final DateTime eventActiveEndDate;

  /// Whether this event's content is authored in more than one language. It
  /// governs this event's own title/description, and tips (and the schedule
  /// models) mirror it onto their own `isMultilingual` flag.
  final bool isMultilingual;

  /// Max push notifications this event may send; null means no limit. Managed by
  /// WeGather (super admin) staff in the admin panel.
  final int? notificationLimit;

  const EventModel({
    required this.id,
    required this.titles,
    required this.descriptions,
    required this.companyId,
    required this.eventLogo,
    required this.eventFeaturedImages,
    required this.eventSlogans,
    required this.eventStartDate,
    required this.eventEndDate,
    required this.eventActiveStartDate,
    required this.eventActiveEndDate,
    required this.isMultilingual,
    required this.notificationLimit,
  });

  /// The title for [locale], falling back to the primary (Turkish) value.
  String titleFor(WgLocale locale) => localizedFor(titles, locale);

  /// The description for [locale], falling back to the primary value.
  String descriptionFor(WgLocale locale) => localizedFor(descriptions, locale);

  /// The featured image URL for [locale], falling back to the primary value.
  String eventFeaturedImgFor(WgLocale locale) =>
      localizedFor(eventFeaturedImages, locale);

  /// The slogan for [locale], falling back to the primary value.
  String eventSloganFor(WgLocale locale) => localizedFor(eventSlogans, locale);

  /// Primary-language title (Turkish).
  String get title => titleFor(WgLocale.tr);

  /// Primary-language description (Turkish).
  String get description => descriptionFor(WgLocale.tr);

  /// Primary-language featured image URL (Turkish); empty when there is none.
  String get eventFeaturedImg => eventFeaturedImgFor(WgLocale.tr);

  /// Primary-language slogan (Turkish); empty when there is none.
  String get eventSlogan => eventSloganFor(WgLocale.tr);

  /// Whether a featured image was set for the primary language.
  bool get hasFeaturedImg => eventFeaturedImg.trim().isNotEmpty;

  /// Whether a slogan was set in any language.
  bool get hasSlogan => eventSlogans.values.any((v) => v.trim().isNotEmpty);

  /// Whether [now] falls inside the event's platform-active window.
  ///
  /// Nothing enforces this yet — events are listed regardless of their window.
  /// Filter accessible events on this once the active-window rules go live.
  bool isActiveAt(DateTime now) =>
      !now.isBefore(eventActiveStartDate) && !now.isAfter(eventActiveEndDate);

  factory EventModel.fromJson(String id, Map<String, dynamic> json) {
    // Read the flag first: it decides how title/description are shaped.
    final isMultilingual = json['isMultilingual'] as bool? ?? false;
    return EventModel(
      id: id,
      titles: parseLocalizedText(json['title'], isMultilingual),
      descriptions: parseLocalizedText(json['description'], isMultilingual),
      companyId: json['companyId'] as String? ?? '',
      eventLogo: json['eventLogo'] as String? ?? '',
      eventFeaturedImages: parseLocalizedText(
        json['eventFeaturedImg'],
        isMultilingual,
      ),
      // `eventSlogan` is pruned from the document when blank in every language,
      // so a missing value parses to empty strings rather than being an error.
      eventSlogans: parseLocalizedText(json['eventSlogan'], isMultilingual),
      eventStartDate: _toDate(json['eventStartDate']),
      eventEndDate: _toDate(json['eventEndDate']),
      eventActiveStartDate: _toDate(json['eventActiveStartDate']),
      eventActiveEndDate: _toDate(json['eventActiveEndDate']),
      isMultilingual: isMultilingual,
      notificationLimit: (json['notificationLimit'] as num?)?.toInt(),
    );
  }

  /// Serialize back to the Firestore shape. The app only reads events (the admin
  /// panel writes them), but a symmetric `toJson` keeps the model testable and
  /// the wire format documented. Optional fields empty in every language (or
  /// unset) are pruned to match what the admin panel writes.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': localizedTextToJson(titles, isMultilingual),
      'description': localizedTextToJson(descriptions, isMultilingual),
      'companyId': companyId,
      'eventLogo': eventLogo,
      // Written like eventLogo — always present (blank when unset), so a language
      // with no hero image simply carries an empty string.
      'eventFeaturedImg': localizedTextToJson(
        eventFeaturedImages,
        isMultilingual,
      ),
      'eventStartDate': Timestamp.fromDate(eventStartDate),
      'eventEndDate': Timestamp.fromDate(eventEndDate),
      'eventActiveStartDate': Timestamp.fromDate(eventActiveStartDate),
      'eventActiveEndDate': Timestamp.fromDate(eventActiveEndDate),
      'isMultilingual': isMultilingual,
    };

    if (hasSlogan) {
      json['eventSlogan'] = localizedTextToJson(eventSlogans, isMultilingual);
    }
    if (notificationLimit != null) {
      json['notificationLimit'] = notificationLimit;
    }
    return json;
  }

  /// Accepts a [Timestamp], a [DateTime] or epoch millis so callers aren't
  /// coupled to one representation (matches the panel's `toDate`).
  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
