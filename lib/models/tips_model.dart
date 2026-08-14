import 'localized_text.dart';

/// The kind of content a tip holds. The string values match the JSON payload.
enum TipType {
  text('text'),
  richText('rich_text'),
  gallery('gallery'),
  file('file');

  const TipType(this.jsonValue);

  final String jsonValue;

  static TipType fromJson(String value) => TipType.values.firstWhere(
    (t) => t.jsonValue == value,
    orElse: () => TipType.text,
  );
}

/// The languages a multilingual tip is authored in — the app-wide [WgLocale],
/// aliased so tip code keeps reading as `TipLocale`. Kept in sync with the admin
/// panel's `TipLocale` (`types/tips.ts`), which is likewise an alias.
typedef TipLocale = WgLocale;

/// A single tip.
///
/// [tipType] is the source of truth for the payload shape; [isMultilingual]
/// decides whether the title/content are bare values or per-locale maps.
///
/// Multilingual tips carry a value per [TipLocale]; mono tips store a single,
/// language-agnostic value under [TipLocale.tr]. The [title]/[content] getters
/// default to the primary (Turkish) language so existing displayers keep
/// working — swap them for [titleFor]/[contentFor] once the app adds a language
/// switch.
class TipModel {
  final String id;
  final String icon;
  final bool isMultilingual;
  final TipType tipType;
  final Map<TipLocale, String> titles;
  final Map<TipLocale, TipContent> contents;

  const TipModel({
    required this.id,
    required this.icon,
    required this.isMultilingual,
    required this.tipType,
    required this.titles,
    required this.contents,
  });

  /// The title for [locale], falling back to the primary (Turkish) value.
  String titleFor(TipLocale locale) =>
      titles[locale] ?? titles[TipLocale.tr] ?? '';

  /// The content for [locale], falling back to the primary (Turkish) value.
  TipContent contentFor(TipLocale locale) =>
      contents[locale] ?? contents[TipLocale.tr] ?? const TextTipContent('');

  /// Primary-language title (Turkish).
  String get title => titleFor(TipLocale.tr);

  /// Primary-language content (Turkish).
  TipContent get content => contentFor(TipLocale.tr);

  factory TipModel.fromJson(Map<String, dynamic> json) {
    final type = TipType.fromJson(json['tipType'] ?? json['type'] ?? 'text');
    final isMultilingual =
        json['isMultilingual'] as bool? ?? isLocaleMap(json['content']);

    final titles = <TipLocale, String>{};
    final contents = <TipLocale, TipContent>{};

    if (isMultilingual) {
      final titleMap = (json['title'] as Map?) ?? const {};
      final contentMap = (json['content'] as Map?) ?? const {};
      for (final locale in TipLocale.values) {
        titles[locale] = titleMap[locale.jsonValue] as String? ?? '';
        contents[locale] = TipContent.fromJson(
          type,
          contentMap[locale.jsonValue],
        );
      }
    } else {
      titles[TipLocale.tr] = json['title'] as String? ?? '';
      contents[TipLocale.tr] = TipContent.fromJson(type, json['content']);
    }

    return TipModel(
      id: json['id'] ?? '',
      icon: json['icon'] ?? '',
      isMultilingual: isMultilingual,
      tipType: type,
      titles: titles,
      contents: contents,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'icon': icon,
    'tipType': tipType.jsonValue,
    'isMultilingual': isMultilingual,
    'title': isMultilingual
        ? {for (final l in TipLocale.values) l.jsonValue: titles[l] ?? ''}
        : titles[TipLocale.tr] ?? '',
    'content': isMultilingual
        ? {
            for (final l in TipLocale.values)
              l.jsonValue: (contents[l] ?? const TextTipContent(''))
                  .toJsonContent(),
          }
        : content.toJsonContent(),
  };
}

/// The tip's payload. Sealed so that a tip is guaranteed to hold exactly one of
/// the known content shapes, and so `switch`es over it are exhaustively checked
/// by the compiler.
sealed class TipContent {
  const TipContent();

  TipType get type;

  /// The raw JSON value stored under the `content` key (shape varies by type).
  Object? toJsonContent();

  factory TipContent.fromJson(TipType type, dynamic content) {
    switch (type) {
      case TipType.text:
        return TextTipContent.fromJson(content);
      case TipType.richText:
        return RichTextTipContent.fromJson(content);
      case TipType.gallery:
        return GalleryTipContent.fromJson(content);
      case TipType.file:
        return FileTipContent.fromJson(content);
    }
  }
}

/// Plain text, rendered the same way as the KVKK / Terms pages.
class TextTipContent extends TipContent {
  final String text;

  const TextTipContent(this.text);

  @override
  TipType get type => TipType.text;

  factory TextTipContent.fromJson(dynamic content) =>
      TextTipContent(content as String? ?? '');

  @override
  Object? toJsonContent() => text;
}

/// Rich text made up of ordered blocks (headers, paragraphs, images, …).
///
/// NOTE: the block schema below is a starting point — adjust it once the rich
/// text format is finalized.
class RichTextTipContent extends TipContent {
  final List<RichTextBlock> blocks;

  const RichTextTipContent(this.blocks);

  @override
  TipType get type => TipType.richText;

  factory RichTextTipContent.fromJson(dynamic content) {
    final list = (content as List? ?? const []);
    return RichTextTipContent(
      list
          .map((b) => RichTextBlock.fromJson(Map<String, dynamic>.from(b)))
          .toList(),
    );
  }

  @override
  Object? toJsonContent() => blocks.map((b) => b.toJson()).toList();
}

/// A gallery: an ordered list of image URLs.
class GalleryTipContent extends TipContent {
  final List<String> imageUrls;

  const GalleryTipContent(this.imageUrls);

  @override
  TipType get type => TipType.gallery;

  factory GalleryTipContent.fromJson(dynamic content) =>
      GalleryTipContent(List<String>.from(content as List? ?? const []));

  @override
  Object? toJsonContent() => imageUrls;
}

/// A single downloadable/viewable file, referenced by URL.
class FileTipContent extends TipContent {
  final String fileUrl;

  const FileTipContent(this.fileUrl);

  @override
  TipType get type => TipType.file;

  factory FileTipContent.fromJson(dynamic content) =>
      FileTipContent(content as String? ?? '');

  @override
  Object? toJsonContent() => fileUrl;
}

/// A block within [RichTextTipContent]. Placeholder schema — extend as needed.
sealed class RichTextBlock {
  const RichTextBlock();

  Map<String, dynamic> toJson();

  factory RichTextBlock.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'header':
        return HeaderBlock(json['text'] ?? '', level: json['level'] ?? 1);
      case 'image':
        return ImageBlock(json['url'] ?? '');
      case 'paragraph':
      default:
        return ParagraphBlock(json['text'] ?? '');
    }
  }
}

class HeaderBlock extends RichTextBlock {
  final String text;
  final int level;

  const HeaderBlock(this.text, {this.level = 1});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'header',
    'text': text,
    'level': level,
  };
}

class ParagraphBlock extends RichTextBlock {
  final String text;

  const ParagraphBlock(this.text);

  @override
  Map<String, dynamic> toJson() => {'type': 'paragraph', 'text': text};
}

class ImageBlock extends RichTextBlock {
  final String url;

  const ImageBlock(this.url);

  @override
  Map<String, dynamic> toJson() => {'type': 'image', 'url': url};
}
