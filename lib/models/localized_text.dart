/// Locale primitives shared by every localisable model (events, tips, and the
/// schedule models when they land). Kept in sync with the admin panel's
/// `types/locales.ts`.
///
/// The convention, everywhere: a localisable field is stored **bare when mono
/// and as a `{tr, en}` map when multilingual**, with the owning document
/// carrying its own `isMultilingual` flag so it is self-describing (a reader
/// never has to fetch the event to parse it).
///
///     mono:          title: "Opening keynote"
///     multilingual:  title: {"tr": "Açılış konuşması", "en": "Opening keynote"}
///
/// In Dart a parsed field is always a `Map<WgLocale, String>`: a mono value
/// simply lives under [WgLocale.tr], which keeps readers uniform.
library;

/// The languages content is authored in (fixed pair for now).
enum WgLocale {
  tr('tr'),
  en('en');

  const WgLocale(this.jsonValue);

  final String jsonValue;

  /// Unknown/missing values fall back to the primary language.
  static WgLocale fromJson(String? value) => WgLocale.values.firstWhere(
    (l) => l.jsonValue == value,
    orElse: () => WgLocale.tr,
  );
}

/// Whether a decoded value is a `{tr, en}` locale map rather than a bare value.
/// Used to read documents that predate the `isMultilingual` flag.
bool isLocaleMap(dynamic value) =>
    value is Map && (value.containsKey('tr') || value.containsKey('en'));

/// Parse a localised string field into a value per [WgLocale].
///
/// [isMultilingual] comes from the owning document, so a value written before
/// its event was switched to multilingual still parses (and displays) as mono. A
/// bare string found on a multilingual document seeds every locale rather than
/// being dropped.
Map<WgLocale, String> parseLocalizedText(dynamic value, bool isMultilingual) {
  if (!isMultilingual) {
    return {WgLocale.tr: value as String? ?? ''};
  }
  if (value is String) {
    return {for (final l in WgLocale.values) l: value};
  }
  final map = (value as Map?) ?? const {};
  return {
    for (final l in WgLocale.values) l: map[l.jsonValue] as String? ?? '',
  };
}

/// The raw JSON for a localised string: bare when mono, `{tr, en}` when not.
Object localizedTextToJson(Map<WgLocale, String> values, bool isMultilingual) =>
    isMultilingual
    ? {for (final l in WgLocale.values) l.jsonValue: values[l] ?? ''}
    : values[WgLocale.tr] ?? '';

/// The value for [locale], falling back to the primary (Turkish) one.
String localizedFor(Map<WgLocale, String> values, WgLocale locale) =>
    values[locale] ?? values[WgLocale.tr] ?? '';
