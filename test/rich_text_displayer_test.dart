import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegather_app/image_widgets/wg_image_grid.dart';
import 'package:wegather_app/models/tips_model.dart';
import 'package:wegather_app/tip_widgets/rich_text_displayer.dart';

/// Tests for the rich-text article layout. Network fetches fail under
/// `flutter test`, so every image resolves to its error placeholder — these
/// check ordering and spacing, not pixels.
void main() {
  Widget wrap(List<RichTextBlock> blocks) => MaterialApp(
    home: Scaffold(body: RichTextBlockList(blocks: blocks)),
  );

  /// Vertical distance between the bottom of [above] and the top of [below].
  double gapBetween(WidgetTester tester, Finder above, Finder below) =>
      tester.getTopLeft(below).dy - tester.getBottomLeft(above).dy;

  testWidgets('renders every block type in document order', (tester) async {
    await tester.pumpWidget(
      wrap(const [
        HeaderBlock('Getting here', level: 1),
        ParagraphBlock('Take the shuttle from the north gate.'),
        ImageBlock('https://example.com/map.jpg'),
      ]),
    );

    expect(find.text('Getting here'), findsOneWidget);
    expect(find.text('Take the shuttle from the north gate.'), findsOneWidget);
    expect(find.byType(WgImagePlaceholder), findsOneWidget);

    expect(
      tester.getTopLeft(find.text('Getting here')).dy,
      lessThan(tester.getTopLeft(find.byType(WgImagePlaceholder)).dy),
    );
  });

  testWidgets('leaves 16pt above and below an image', (tester) async {
    await tester.pumpWidget(
      wrap(const [
        ParagraphBlock('Before'),
        ImageBlock('https://example.com/map.jpg'),
        ParagraphBlock('After'),
      ]),
    );

    final image = find.byType(WgImagePlaceholder);
    expect(gapBetween(tester, find.text('Before'), image), 16);
    expect(gapBetween(tester, image, find.text('After')), 16);
  });

  testWidgets('drops blocks an author left blank', (tester) async {
    await tester.pumpWidget(
      wrap(const [
        ParagraphBlock('Before'),
        ParagraphBlock('   '),
        HeaderBlock(''),
        ImageBlock(''),
        ParagraphBlock('After'),
      ]),
    );

    expect(find.byType(WgImagePlaceholder), findsNothing);
    // The two survivors sit a plain paragraph gap apart, as if the blanks were
    // never in the document.
    expect(gapBetween(tester, find.text('Before'), find.text('After')), 12);
  });

  testWidgets('rounds article images to 8pt', (tester) async {
    await tester.pumpWidget(
      wrap(const [ImageBlock('https://example.com/map.jpg')]),
    );

    final clip = tester.widget<ClipRRect>(
      find
          .ancestor(
            of: find.byType(WgImagePlaceholder),
            matching: find.byType(ClipRRect),
          )
          .first,
    );
    expect(clip.borderRadius, BorderRadius.circular(8));
  });

  testWidgets('shows an empty state when nothing has content', (tester) async {
    await tester.pumpWidget(wrap(const [ParagraphBlock('')]));

    expect(find.text('Nothing here yet.'), findsOneWidget);
  });

  testWidgets('sizes headers by level', (tester) async {
    await tester.pumpWidget(
      wrap(const [
        HeaderBlock('One', level: 1),
        HeaderBlock('Two', level: 2),
        HeaderBlock('Three', level: 3),
      ]),
    );

    double fontSize(String text) =>
        tester.widget<Text>(find.text(text)).style!.fontSize!;

    expect(fontSize('One'), greaterThan(fontSize('Two')));
    expect(fontSize('Two'), greaterThan(fontSize('Three')));
  });
}
