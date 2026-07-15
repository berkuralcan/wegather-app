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

/// A single tip.
///
/// [content] is the source of truth for the tip's type — [tipType] is derived
/// from it, so the two can never disagree.
class TipModel {
  final String id;
  final String title;
  final String icon;
  final TipContent content;

  const TipModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.content,
  });

  TipType get tipType => content.type;

  factory TipModel.fromJson(Map<String, dynamic> json) {
    final type = TipType.fromJson(json['tipType'] ?? json['type'] ?? 'text');
    return TipModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      icon: json['icon'] ?? '',
      content: TipContent.fromJson(type, json['content']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'icon': icon,
    'tipType': tipType.jsonValue,
    'content': content.toJsonContent(),
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
