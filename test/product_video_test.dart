import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/features/product/widgets/image_gallery.dart';
import 'package:ecommerce_app/features/product/widgets/product_video.dart';
import 'package:ecommerce_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: Scaffold(body: SizedBox(height: 400, child: child)),
  );

  group('a product carrying a clip', () {
    test('round-trips through JSON', () {
      final Product p = testProduct(
        videos: <String>['https://example.invalid/clip.mp4'],
      );

      final Product back = Product.fromJson(p.toJson());
      expect(back.videos, <String>['https://example.invalid/clip.mp4']);
    });

    test('an item without one carries an empty list, not a null', () {
      final Product back = Product.fromJson(testProduct().toJson());
      expect(back.videos, isEmpty);
    });
  });

  group('the gallery', () {
    testWidgets('leads with the clip and counts it among the dots', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const ImageGallery(
            images: <String>['https://example.invalid/1.webp'],
            videos: <String>['https://example.invalid/clip.mp4'],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ProductVideo), findsOneWidget);
      // One clip plus one photo, so the page it opens on is the clip.
      expect(find.text('Tap to zoom'), findsNothing);
    });

    testWidgets('says nothing about zoom until a photo is on screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const ImageGallery(
            images: <String>['https://example.invalid/1.webp'],
            videos: <String>['https://example.invalid/clip.mp4'],
          ),
        ),
      );
      await tester.pump();

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await settle(tester);

      expect(find.text('Tap to zoom'), findsOneWidget);
    });

    testWidgets('a product with no clip is exactly as it was', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const ImageGallery(
            images: <String>['https://example.invalid/1.webp'],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ProductVideo), findsNothing);
      expect(find.text('Tap to zoom'), findsOneWidget);
    });
  });

  group('the player', () {
    testWidgets('fetches nothing until it is asked to', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(const ProductVideo(url: 'https://example.invalid/clip.mp4')),
      );
      await tester.pump();

      // A still frame with a play button on it, and no video surface yet.
      expect(find.bySemanticsLabel('Play video'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('a clip that will not load says so instead of throwing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(const ProductVideo(url: 'https://example.invalid/clip.mp4')),
      );
      await tester.pump();

      // No video platform implementation under the test binding, which is
      // the same shape of failure as a dead URL on a device.
      await tester.tap(find.bySemanticsLabel('Play video'));
      await tester.pump();
      // Nothing ever answers, so this is the timeout expiring rather than
      // an error coming back.
      await tester.pump(ProductVideo.timeout + const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('This clip would not load'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
