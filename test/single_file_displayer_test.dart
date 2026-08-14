import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wegather_app/image_widgets/wg_image_viewer.dart';
import 'package:wegather_app/models/tips_model.dart';
import 'package:wegather_app/tip_widgets/single_file_displayer.dart';

/// The routing decision for a file tip is the whole of its logic — everything
/// after it is a viewer that already has its own tests. These pin the URL
/// shapes the admin panel actually produces.
///
/// The PDF branch is left to a manual check: opening it downloads the document
/// through the disk cache, which is not something `flutter test` can serve.
void main() {
  group('kindOf', () {
    test('reads the extension of a plain URL', () {
      expect(
        SingleFileDisplayer.kindOf('https://example.com/menu.pdf'),
        FileKind.pdf,
      );
      expect(
        SingleFileDisplayer.kindOf('https://example.com/floorplan.png'),
        FileKind.image,
      );
    });

    test('ignores a query string', () {
      expect(
        SingleFileDisplayer.kindOf('https://example.com/menu.pdf?v=2&x=y'),
        FileKind.pdf,
      );
    });

    test('decodes a Firebase Storage object path', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/wegather.appspot.com/o/'
          'companies%2Fc1%2Fevents%2Fe1%2Fvenue-map.pdf?alt=media&token=abc123';
      expect(SingleFileDisplayer.kindOf(url), FileKind.pdf);
    });

    test('is case insensitive', () {
      expect(
        SingleFileDisplayer.kindOf('https://example.com/SCAN.PDF'),
        FileKind.pdf,
      );
      expect(
        SingleFileDisplayer.kindOf('https://example.com/Photo.JPEG'),
        FileKind.image,
      );
    });

    test('falls back to unsupported for anything else', () {
      expect(
        SingleFileDisplayer.kindOf('https://example.com/notes.docx'),
        FileKind.unsupported,
      );
      // No extension to go on.
      expect(
        SingleFileDisplayer.kindOf('https://example.com/download'),
        FileKind.unsupported,
      );
      // Not a URL at all.
      expect(SingleFileDisplayer.kindOf('not a url'), FileKind.unsupported);
      expect(SingleFileDisplayer.kindOf(''), FileKind.unsupported);
    });

    test('does not mistake a directory name for a file extension', () {
      expect(
        SingleFileDisplayer.kindOf('https://example.com/pdf/report.docx'),
        FileKind.unsupported,
      );
    });
  });

  group('rendering', () {
    // CustomAppBar asks `context.canPop()`, which needs a router above it.
    Widget wrap(String fileUrl) => MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => SingleFileDisplayer(
              title: 'Venue map',
              content: FileTipContent(fileUrl),
            ),
          ),
        ],
      ),
    );

    testWidgets('opens an image in the shared image viewer', (tester) async {
      await tester.pumpWidget(wrap('https://example.com/map.png'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(WgImageViewer), findsOneWidget);
      // A set of one needs no filmstrip.
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('offers the browser for a file it cannot draw', (tester) async {
      await tester.pumpWidget(wrap('https://example.com/notes.docx'));

      expect(find.text('This file cannot be previewed in the app.'), findsOne);
      expect(find.text('Open in browser'), findsOne);
    });

    testWidgets('says so when no file is attached', (tester) async {
      await tester.pumpWidget(wrap(''));

      expect(find.text('No file attached.'), findsOne);
      expect(find.text('Open in browser'), findsNothing);
    });
  });
}
