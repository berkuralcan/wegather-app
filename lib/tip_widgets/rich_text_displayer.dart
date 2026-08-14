import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wegather_app/config/text_styles.dart';
import 'package:wegather_app/image_widgets/wg_image_grid.dart';
import 'package:wegather_app/image_widgets/wg_image_viewer.dart';
import 'package:wegather_app/layouts/wegather_appbar.dart';
import 'package:wegather_app/models/gallery_image.dart';
import 'package:wegather_app/models/tips_model.dart';

/// Displays a rich-text tip as a page.
///
/// Thin on purpose — [RichTextBlockList] holds the layout, so anything else
/// with a block list can render it the same way.
class RichTextDisplayer extends StatelessWidget {
  const RichTextDisplayer({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final RichTextTipContent content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: SafeArea(
        top: false,
        child: RichTextBlockList(blocks: content.blocks, title: title),
      ),
    );
  }
}

/// Renders an ordered [RichTextBlock] list as a scrollable article.
///
/// The admin panel's `RichTextEditor.vue` can only author three kinds of block
/// — a header (levels 1–3), a paragraph, and a single image — with no inline
/// formatting, links or lists, so this handles exactly those. The `switch`es
/// below are exhaustive over the sealed hierarchy, which makes adding a fourth
/// block type a compile error here rather than a silently dropped block.
class RichTextBlockList extends StatelessWidget {
  const RichTextBlockList({super.key, required this.blocks, this.title});

  final List<RichTextBlock> blocks;

  /// Shown in the app bar of the viewer an image opens into.
  final String? title;

  /// Horizontal inset, matching the app bar back arrow's glyph: the arrow sits
  /// in a 56pt leading slot, centred as a 40pt button with 8pt of internal
  /// padding, which puts its glyph 16pt from the screen edge.
  static const double _horizontalInset = 16;

  /// Vertical rhythm. An image is separated from whatever sits on either side
  /// of it by [_imageGap]; the rest of the scale keeps a header tied to the
  /// text it introduces and away from the section it ends.
  static const double _imageGap = 16;
  static const double _beforeHeaderGap = 24;
  static const double _afterHeaderGap = 8;
  static const double _paragraphGap = 12;

  /// Blocks an author left blank — an added-but-never-filled editor row — carry
  /// no content but would still take up a gap, so they are dropped up front.
  static bool _hasContent(RichTextBlock block) => switch (block) {
    HeaderBlock() => block.text.trim().isNotEmpty,
    ParagraphBlock() => block.text.trim().isNotEmpty,
    ImageBlock() => block.url.isNotEmpty,
  };

  static double _gapBetween(RichTextBlock previous, RichTextBlock current) {
    if (previous is ImageBlock || current is ImageBlock) return _imageGap;
    if (current is HeaderBlock) return _beforeHeaderGap;
    if (previous is HeaderBlock) return _afterHeaderGap;
    return _paragraphGap;
  }

  @override
  Widget build(BuildContext context) {
    final visible = blocks.where(_hasContent).toList(growable: false);

    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(_horizontalInset),
          child: Text(
            'Nothing here yet.',
            textAlign: TextAlign.center,
            style: AppTextStyles.weGatherParagraphTextStyle,
          ),
        ),
      );
    }

    // Every image in the article, in document order: tapping one opens the
    // viewer on the whole set, so the filmstrip pages through the article's
    // images rather than stranding the reader on the one they tapped.
    final images = <GalleryImage>[];
    // Block index -> position of that block's image within [images].
    final imageIndices = <int, int>{};
    for (var i = 0; i < visible.length; i++) {
      final block = visible[i];
      if (block is ImageBlock) {
        imageIndices[i] = images.length;
        images.add(GalleryImage(block.url));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(_horizontalInset),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final block = visible[index];
        return Padding(
          padding: EdgeInsets.only(
            top: index == 0 ? 0 : _gapBetween(visible[index - 1], block),
          ),
          child: switch (block) {
            HeaderBlock() => Text(block.text, style: _headerStyle(block.level)),
            ParagraphBlock() => Text(
              block.text,
              style: AppTextStyles.weGatherParagraphTextStyle,
            ),
            ImageBlock() => _RichTextImage(
              images: images,
              index: imageIndices[index]!,
              title: title,
            ),
          },
        );
      },
    );
  }

  /// Levels outside 1–3 cannot be authored today, but a document written by an
  /// older or newer panel still has to render as *something*.
  static TextStyle _headerStyle(int level) => switch (level) {
    <= 1 => AppTextStyles.weGatherHeading1TextStyle,
    2 => AppTextStyles.weGatherHeading2TextStyle,
    _ => AppTextStyles.weGatherHeading3TextStyle,
  };
}

/// A full-width image inside an article, drawn at its own aspect ratio and
/// opening [WgImageViewer] when tapped.
class _RichTextImage extends StatelessWidget {
  const _RichTextImage({
    required this.images,
    required this.index,
    required this.title,
  });

  final List<GalleryImage> images;
  final int index;
  final String? title;

  /// Reserved while the image loads, so the article settles into roughly its
  /// final length instead of jumping once each image arrives.
  static const double _placeholderAspectRatio = 16 / 9;

  static const double _cornerRadius = 8;

  @override
  Widget build(BuildContext context) {
    // Decode at the width the image is actually drawn at rather than the width
    // it was uploaded at — see the note in [WgImageGrid] for why this matters.
    final drawnWidth =
        MediaQuery.sizeOf(context).width -
        RichTextBlockList._horizontalInset * 2;
    final cacheWidth = (drawnWidth * MediaQuery.devicePixelRatioOf(context))
        .round();

    return GestureDetector(
      // Pushed on the root navigator so the viewer covers the bottom nav bar.
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) =>
              WgImageViewer(images: images, initialIndex: index, title: title),
        ),
      ),
      // Rounded here rather than in the shared image widgets: an inline
      // article image reads as its own element, where the gallery grid and the
      // full-screen viewer stay square-cornered.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cornerRadius),
        child: CachedNetworkImage(
          imageUrl: images[index].url,
          // Width only: with no height given the image takes its natural
          // aspect ratio, so a tall portrait shot is not cropped to a
          // letterbox.
          width: double.infinity,
          fit: BoxFit.fitWidth,
          memCacheWidth: cacheWidth,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, _) => const AspectRatio(
            aspectRatio: _placeholderAspectRatio,
            child: WgImagePlaceholder(),
          ),
          errorWidget: (_, _, _) => const AspectRatio(
            aspectRatio: _placeholderAspectRatio,
            child: WgImagePlaceholder(failed: true),
          ),
        ),
      ),
    );
  }
}
