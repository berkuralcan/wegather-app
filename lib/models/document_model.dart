import 'package:cloud_firestore/cloud_firestore.dart';
import 'localized_text.dart';

/// A single document.
///
/// Documents live in a subcollection of their event —
/// `events/{eventId}/documents/{id}` — and inherit its access. A document is a
/// stripped-down tip: the "file" tip type, one file per entry. Writes happen in
/// the admin panel only (`composables/useDocuments.ts`); the app reads them.
///
/// [fileName] and the optional [description] are localised and follow the shared
/// "bare when mono, `{tr, en}` map when multilingual" convention (see
/// [parseLocalizedText]); a mono value simply lives under [WgLocale.tr].
/// [fileUrl] is a single shared file and is not localised. The
/// `fileName`/`description` getters default to the primary (Turkish) language;
/// swap them for [fileNameFor]/[descriptionFor] once the app adds a language
/// switch.
///
/// Kept in sync with the admin panel's `types/documents.ts`.
class DocumentModel {
  final String id;
  final bool isMultilingual;
  final Map<WgLocale, String> fileNames;
  final Map<WgLocale, String> descriptions;
  final String fileUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String updatedBy;

  const DocumentModel({
    required this.id,
    required this.isMultilingual,
    required this.fileNames,
    required this.descriptions,
    required this.fileUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  /// The file name for [locale], falling back to the primary (Turkish) value.
  String fileNameFor(WgLocale locale) => localizedFor(fileNames, locale);

  /// The description for [locale], falling back to the primary (Turkish) value.
  String descriptionFor(WgLocale locale) => localizedFor(descriptions, locale);

  /// Primary-language file name (Turkish).
  String get fileName => fileNameFor(WgLocale.tr);

  /// Primary-language description (Turkish); empty when there is none.
  String get description => descriptionFor(WgLocale.tr);

  /// Whether the primary-language description is set.
  bool get hasDescription => description.trim().isNotEmpty;

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final isMultilingual =
        json['isMultilingual'] as bool? ?? isLocaleMap(json['fileName']);

    return DocumentModel(
      id: json['id'] as String? ?? '',
      isMultilingual: isMultilingual,
      fileNames: parseLocalizedText(json['fileName'], isMultilingual),
      // `description` is pruned from the document when blank in every language,
      // so a missing value parses to empty strings rather than being an error.
      descriptions: parseLocalizedText(json['description'], isMultilingual),
      fileUrl: json['fileUrl'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: json['createdBy'] as String? ?? '',
      updatedBy: json['updatedBy'] as String? ?? '',
    );
  }

  /// Serialize back to the Firestore shape. The app only reads documents (the
  /// admin panel writes them), but a symmetric `toJson` keeps the model testable
  /// and the wire format documented. An empty description is pruned to match what
  /// the admin panel writes.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'isMultilingual': isMultilingual,
      'fileName': localizedTextToJson(fileNames, isMultilingual),
      'fileUrl': fileUrl,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };

    if (descriptions.values.any((v) => v.trim().isNotEmpty)) {
      json['description'] = localizedTextToJson(descriptions, isMultilingual);
    }
    return json;
  }
}
