import 'package:cloud_firestore/cloud_firestore.dart';
import 'localized_text.dart';

/// A single announcement.
///
/// Announcements live in a subcollection of their event —
/// `events/{eventId}/announcements/{id}` — and inherit its access. They are the
/// simplest piece of content in the app: essentially a text tip with an optional
/// link and a featured image. Writes happen in the admin panel only
/// (`composables/useAnnouncements.ts`); the app reads them.
///
/// [title], [content] and [url] are localised and follow the shared "bare when
/// mono, `{tr, en}` map when multilingual" convention (see [parseLocalizedText]);
/// a mono value simply lives under [WgLocale.tr]. [featuredImage] is a single
/// shared image and is not localised. The `title`/`content`/`url` getters default
/// to the primary (Turkish) language so callers stay simple until the app adds a
/// language switch — swap them for [titleFor]/[contentFor]/[urlFor] then.
///
/// Kept in sync with the admin panel's `types/anouncements.ts`.
class AnnouncementModel {
  final String id;
  final bool isMultilingual;
  final Map<WgLocale, String> titles;
  final Map<WgLocale, String> contents;
  final Map<WgLocale, String> urls;
  final String featuredImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  const AnnouncementModel({
    required this.id,
    required this.isMultilingual,
    required this.titles,
    required this.contents,
    required this.urls,
    required this.featuredImage,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  /// The title for [locale], falling back to the primary (Turkish) value.
  String titleFor(WgLocale locale) => localizedFor(titles, locale);

  /// The content for [locale], falling back to the primary (Turkish) value.
  String contentFor(WgLocale locale) => localizedFor(contents, locale);

  /// The link for [locale], falling back to the primary (Turkish) value.
  String urlFor(WgLocale locale) => localizedFor(urls, locale);

  /// Primary-language title (Turkish).
  String get title => titleFor(WgLocale.tr);

  /// Primary-language content (Turkish).
  String get content => contentFor(WgLocale.tr);

  /// Primary-language link (Turkish); empty when there is none.
  String get url => urlFor(WgLocale.tr);

  /// Whether a featured image was set.
  bool get hasFeaturedImage => featuredImage.trim().isNotEmpty;

  /// Whether the primary-language link is set.
  bool get hasUrl => url.trim().isNotEmpty;

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final isMultilingual =
        json['isMultilingual'] as bool? ?? isLocaleMap(json['content']);

    return AnnouncementModel(
      id: json['id'] as String? ?? '',
      isMultilingual: isMultilingual,
      titles: parseLocalizedText(json['title'], isMultilingual),
      contents: parseLocalizedText(json['content'], isMultilingual),
      // `url` is pruned from the document when blank in every language, so a
      // missing value parses to empty strings rather than being an error.
      urls: parseLocalizedText(json['url'], isMultilingual),
      featuredImage: json['featuredImage'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: json['createdBy'] as String? ?? '',
    );
  }

  /// Serialize back to the Firestore shape. The app only reads announcements
  /// (the admin panel writes them), but a symmetric `toJson` keeps the model
  /// testable and the wire format documented. Empty optional fields are pruned
  /// to match what the admin panel writes.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'isMultilingual': isMultilingual,
      'title': localizedTextToJson(titles, isMultilingual),
      'content': localizedTextToJson(contents, isMultilingual),
      'createdBy': createdBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };

    if (urls.values.any((v) => v.trim().isNotEmpty)) {
      json['url'] = localizedTextToJson(urls, isMultilingual);
    }
    if (hasFeaturedImage) {
      json['featuredImage'] = featuredImage;
    }
    return json;
  }
}
