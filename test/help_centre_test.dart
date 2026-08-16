import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:flutter/material.dart';
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
    products: <Product>[testProduct()],
  );

  Future<void> openHelp(WidgetTester tester) async {
    useMobileSurface(tester);
    setMockPrefs();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository(catalog),
          ),
        ],
        child: const AsterApp(),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Profile').last);
    await settle(tester);
    await tester.tap(find.text('Help center'));
    await settle(tester);
  }

  testWidgets('opens from Profile instead of a coming-soon snackbar', (
    WidgetTester tester,
  ) async {
    await openHelp(tester);

    expect(find.text('Aster is a demo storefront'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('an answer is behind its question', (WidgetTester tester) async {
    await openHelp(tester);

    const String question = 'How long do I have to return something?';
    expect(find.text(question), findsOneWidget);
    expect(find.textContaining('days from the day'), findsNothing);

    await tester.tap(find.text(question));
    await settle(tester);

    // The window is quoted from the model, so the two can't drift apart.
    expect(
      find.textContaining('${Order.returnWindow.inDays} days from the day'),
      findsOneWidget,
    );
  });
}
