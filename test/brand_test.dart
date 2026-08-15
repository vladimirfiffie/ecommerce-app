import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/core/router/app_router.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/features/product/widgets/specs_section.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/brand_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);
  setUp(stubHaptics);

  final Catalog catalog = Catalog(
    categories: <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: '',
      ),
    ],
    products: <Product>[
      testProduct(
        id: 'coat',
        name: 'Wool Coat',
        brand: 'Aurora',
        price: 120,
        compareAtPrice: 160,
        rating: 4.8,
        isFeatured: true,
      ),
      testProduct(
        id: 'tee',
        name: 'Linen Tee',
        // Deliberately different casing: brand is free text.
        brand: 'aurora',
        price: 25,
        rating: 4.2,
      ),
      testProduct(
        id: 'boot',
        name: 'Chelsea Boot',
        brand: 'Meridian',
        price: 90,
        rating: 4,
      ),
    ],
  );

  group('Catalog.byBrand', () {
    test('collects a brand regardless of capitalisation', () {
      final List<Product> hits = catalog.byBrand('AURORA');
      expect(hits.map((Product p) => p.id), <String>['coat', 'tee']);
    });

    test('orders best-rated first', () {
      expect(catalog.byBrand('aurora').first.id, 'coat');
    });

    test('an unknown or blank brand comes back empty', () {
      expect(catalog.byBrand('Nobody'), isEmpty);
      expect(catalog.byBrand('   '), isEmpty);
    });
  });

  group('BrandPage', () {
    Future<ProviderContainer> container() async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      return ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository(catalog),
          ),
        ],
      );
    }

    test('summarises count, rating, cheapest and sale lines', () async {
      final ProviderContainer c = await container();
      addTearDown(c.dispose);
      await c.read(catalogProvider.future);

      final BrandPage page = c.read(brandProvider('aurora'));
      expect(page.count, 2);
      expect(page.averageRating, closeTo(4.5, 0.001));
      expect(page.lowestPrice, 25);
      expect(page.onSaleCount, 1);
    });

    test('takes its name from the catalog, not from the link', () async {
      final ProviderContainer c = await container();
      addTearDown(c.dispose);
      await c.read(catalogProvider.future);

      // Arrived lowercase; the page should show the catalog's spelling.
      expect(c.read(brandProvider('AURORA')).name, 'Aurora');
    });

    test('an unknown brand is empty but still keeps its name', () async {
      final ProviderContainer c = await container();
      addTearDown(c.dispose);
      await c.read(catalogProvider.future);

      final BrandPage page = c.read(brandProvider('Nobody'));
      expect(page.isEmpty, isTrue);
      expect(page.name, 'Nobody');
      expect(page.averageRating, isNull);
      expect(page.lowestPrice, isNull);
    });
  });

  group('the brand route', () {
    test('escapes names that would otherwise break the path', () {
      expect(Routes.brand('Aurora'), '/brand/Aurora');
      expect(Routes.brand('Glamour Beauty'), '/brand/Glamour%20Beauty');
    });
  });

  group('the brand screen', () {
    Future<void> openBrand(WidgetTester tester) async {
      useMobileSurface(tester);
      setMockPrefs();
      final SharedPreferences store = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository(catalog),
          ),
        ],
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const NovaApp()),
      );
      await settle(tester);

      // Home → product → brand, the way a shopper actually gets there.
      await tester.tap(find.text('Wool Coat').first);
      await settle(tester);
      await tester.tap(find.text('AURORA'));
      await settle(tester);
    }

    testWidgets('is reachable by tapping the brand on a product', (
      WidgetTester tester,
    ) async {
      await openBrand(tester);

      expect(find.text('2 products'), findsOneWidget);
      expect(find.text('Linen Tee'), findsWidgets);
      expect(
        find.text('Chelsea Boot'),
        findsNothing,
        reason: 'that is a different brand',
      );
    });

    testWidgets('shows the numbers worth knowing about the brand', (
      WidgetTester tester,
    ) async {
      await openBrand(tester);

      expect(find.text('4.5 average'), findsOneWidget);
      expect(find.text('From \$25.00'), findsOneWidget);
      expect(find.text('1 on sale'), findsOneWidget);
    });
  });

  group('specifications', () {
    Product withSpecs(ProductSpecs specs) =>
        testProduct(id: 's', name: 'Spec Item', specs: specs);

    test('omits everything the catalog did not supply', () {
      final List<String> labels = SpecsSection.rowsFor(
        withSpecs(ProductSpecs.none),
      ).map((Spec s) => s.label).toList();

      // Category always survives — it comes off the product, not the feed.
      expect(labels, <String>['Category']);
    });

    test('formats dimensions, weight and the small print', () {
      final List<Spec> rows = SpecsSection.rowsFor(
        withSpecs(
          const ProductSpecs(
            widthCm: 15.14,
            heightCm: 13,
            depthCm: 22.99,
            weightGrams: 4,
            warranty: '1 week warranty',
            shipping: 'Ships in 3-5 business days',
            returnPolicy: 'No return policy',
            sku: 'BEA-ESS-001',
          ),
        ),
      );
      final Map<String, String> byLabel = <String, String>{
        for (final Spec s in rows) s.label: s.value,
      };

      expect(byLabel['Dimensions'], '15.1 × 13 × 23.0 cm');
      expect(byLabel['Weight'], '4 g');
      expect(byLabel['Warranty'], '1 week warranty');
      expect(byLabel['SKU'], 'BEA-ESS-001');
    });

    test('switches to kilograms once it is worth it', () {
      String weightOf(double grams) => SpecsSection.rowsFor(
        withSpecs(ProductSpecs(weightGrams: grams)),
      ).firstWhere((Spec s) => s.label == 'Weight').value;

      expect(weightOf(999), '999 g');
      expect(weightOf(1000), '1 kg');
      expect(weightOf(1400), '1.4 kg');
    });

    test('a half-present dimension set is dropped, not half-drawn', () {
      const ProductSpecs partial = ProductSpecs(widthCm: 10, heightCm: 4);
      expect(partial.hasDimensions, isFalse);
      expect(
        SpecsSection.rowsFor(
          withSpecs(partial),
        ).where((Spec s) => s.label == 'Dimensions'),
        isEmpty,
      );
    });

    test('a bulk-only line says so; a normal one stays quiet', () {
      List<String> labelsFor(int? moq) => SpecsSection.rowsFor(
        withSpecs(ProductSpecs(minimumOrderQuantity: moq)),
      ).map((Spec s) => s.label).toList();

      expect(labelsFor(48), contains('Minimum order'));
      expect(labelsFor(1), isNot(contains('Minimum order')));
      expect(labelsFor(null), isNot(contains('Minimum order')));
    });
  });
}
