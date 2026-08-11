import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps tests hermetic: no font downloads, no HTTP.
void configureTestEnvironment() {
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// haptic_kit's method channel, as declared by the package.
const MethodChannel _hapticChannel = MethodChannel('dev.erykkruk/haptic_kit');

/// Answers haptic_kit's platform calls so tests don't hit a missing plugin.
///
/// The test binding reports Android, so the app takes its real haptic paths;
/// without a stub every tick would raise `PlatformVibrationException` from an
/// unawaited future inside the package's own widgets.
void stubHaptics() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_hapticChannel, (MethodCall call) async {
        if (call.method == 'capabilities.query') {
          return <Object?, Object?>{
            'hasVibrator': true,
            'hasAmplitudeControl': true,
            'supportsCustomPatterns': true,
            'supportsPredefinedEffects': true,
            'supportsImpactFeedback': true,
          };
        }
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_hapticChannel, null),
  );
}

/// Gives the test a phone-shaped viewport (360×800 logical).
///
/// The 800×600 default is landscape-ish and pushes the product grid below the
/// fold, so taps land outside the render tree.
void useMobileSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Waits out a floating snackbar, which otherwise sits over the bottom action
/// bar and swallows the next tap.
Future<void> clearSnackBars(WidgetTester tester) async {
  // Dismiss explicitly rather than waiting out the auto-dismiss timer, which
  // doesn't reliably fire under the test binding's fake clock.
  final Finder messenger = find.byType(ScaffoldMessenger);
  if (messenger.evaluate().isNotEmpty) {
    tester.state<ScaffoldMessengerState>(messenger.first).clearSnackBars();
  }
  await settle(tester);
}

/// Advances far enough for entrance animations and async loads to finish.
///
/// [WidgetTester.pumpAndSettle] can't be used here: the image shimmer and the
/// promo carousel run indefinitely by design, so the frame queue never drains.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  // Page transitions run 800ms; two passes covers a push plus its overlay.
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 900));
}

/// Scrolls [target] into view within [scrollable], clear of any bottom bar.
Future<void> revealAndTap(
  WidgetTester tester,
  Finder target, {
  Finder? scrollable,
}) async {
  await tester.dragUntilVisible(
    target,
    scrollable ?? find.byType(Scrollable).first,
    const Offset(0, -120),
  );
  await settle(tester);
  await tester.tap(target);
  await settle(tester);
}

Product testProduct({
  String id = 'p1',
  String name = 'Test Jacket',
  String brand = 'Nova',
  String categoryId = 'fashion',
  double price = 100,
  double? compareAtPrice,
  double rating = 4.5,
  int stock = 10,
  List<String> sizes = const <String>[],
  List<ProductColor> colors = const <ProductColor>[],
  bool isFeatured = false,
  bool isNew = false,
}) => Product(
  id: id,
  name: name,
  brand: brand,
  categoryId: categoryId,
  subcategory: 'Jackets',
  price: price,
  compareAtPrice: compareAtPrice,
  description: 'A test product.',
  images: const <String>['https://example.invalid/1.webp'],
  rating: rating,
  reviewCount: 42,
  stock: stock,
  sizes: sizes,
  colors: colors,
  isFeatured: isFeatured,
  isNew: isNew,
);

/// A repository that returns a fixed catalog with no latency.
class FakeProductRepository implements ProductRepository {
  FakeProductRepository(this.catalog);

  final Catalog catalog;

  /// How many times the catalog was fetched, so a test can prove that a
  /// pull-to-refresh actually went back to the source.
  int loads = 0;
  int cacheClears = 0;

  @override
  Future<Catalog> loadCatalog() async {
    loads++;
    return catalog;
  }

  @override
  void clearCache() => cacheClears++;
}

/// Builds a container wired to in-memory preferences and an optional
/// fixed catalog.
Future<ProviderContainer> testContainer({
  Catalog? catalog,
  Map<String, Object> initialPrefs = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (catalog != null)
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(catalog),
        ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Override for tests that build a second container over the same store.
Override sharedPreferencesProviderOverride(SharedPreferences prefs) =>
    sharedPreferencesProvider.overrideWithValue(prefs);
