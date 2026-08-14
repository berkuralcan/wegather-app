import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wegather_app/image_widgets/wg_image_grid.dart';
import 'package:wegather_app/image_widgets/wg_image_viewer.dart';
import 'package:wegather_app/models/gallery_image.dart';

/// Smoke tests for the shared image components. Network fetches fail under
/// `flutter test`, so these check layout and interaction, not pixels — every
/// image resolves to its error placeholder.
void main() {
  final images = List.generate(
    12,
    (i) => GalleryImage('https://example.com/$i.jpg'),
  );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  /// Anything carrying a [CustomAppBar] needs a router above it — the bar asks
  /// `context.canPop()` to decide whether to draw a back arrow, and go_router
  /// asserts rather than returning false when there is nothing to ask.
  Widget wrapRouted(Widget child) => MaterialApp.router(
    routerConfig: GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => child)],
    ),
  );

  testWidgets('grid lays out four perfect squares per row', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(WgImageGrid(images: images)));

    final tile = tester.getSize(find.byType(WgImagePlaceholder).first);
    expect(tile.width, tile.height, reason: 'tiles must be square');
    // 400 wide, three 4pt gutters between four columns.
    expect(tile.width, (400 - 3 * 4) / 4);
  });

  testWidgets('grid builds lazily rather than every tile', (tester) async {
    await tester.pumpWidget(
      wrap(
        WgImageGrid(
          images: List.generate(
            500,
            (i) => GalleryImage('https://example.com/$i.jpg'),
          ),
        ),
      ),
    );

    expect(find.byType(WgImagePlaceholder).evaluate().length, lessThan(100));
  });

  // The loading spinner runs forever, so pumpAndSettle would never return —
  // these advance the clock by hand instead.
  const settle = Duration(milliseconds: 400);

  testWidgets('viewer shows a filmstrip and pages on thumbnail tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapRouted(WgImageViewer(images: images, title: 'Trip')),
    );
    await tester.pump(settle);

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsWidgets);

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.page, 0);

    await tester.tap(find.byType(AnimatedContainer).at(3));
    await tester.pump();
    await tester.pump(settle);

    expect(pageView.controller!.page, 3);
  });

  testWidgets('viewer hides the filmstrip for a single image', (tester) async {
    await tester.pumpWidget(wrapRouted(WgImageViewer(images: [images.first])));
    await tester.pump(settle);

    expect(find.byType(AnimatedContainer), findsNothing);
  });

  testWidgets('viewer clamps an out-of-range initial index', (tester) async {
    await tester.pumpWidget(
      wrapRouted(WgImageViewer(images: images, initialIndex: 99)),
    );
    await tester.pump(settle);

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.page, images.length - 1);
  });
}
