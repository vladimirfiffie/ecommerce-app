import 'package:ecommerce_app/features/product/widgets/size_guide_sheet.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  Future<void> pumpSheet(WidgetTester tester, SizeChart chart) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SizeGuideSheet(chart: chart)),
      ),
    );
    await settle(tester);
  }

  testWidgets('opens on the chart the product implies', (
    WidgetTester tester,
  ) async {
    await pumpSheet(tester, SizeChart.apparel);

    expect(find.text('Clothing sizes'), findsOneWidget);
    expect(find.text('Chest (in)'), findsOneWidget);
  });

  testWidgets('the dropdown swaps the whole chart', (
    WidgetTester tester,
  ) async {
    // A shopper buying a gift wants a chart this product doesn't imply.
    await pumpSheet(tester, SizeChart.apparel);

    await tester.tap(find.byType(DropdownButtonFormField<SizeChart>));
    await settle(tester);
    await tester.tap(find.text('Women’s shoe sizes').last);
    await settle(tester);

    expect(find.text('EU'), findsOneWidget);
    expect(find.text('Chest (in)'), findsNothing);
    // The measuring advice follows the chart, not the product.
    expect(find.textContaining('heel to longest toe'), findsOneWidget);
  });

  testWidgets('every chart is reachable', (WidgetTester tester) async {
    await pumpSheet(tester, SizeChart.mensShoes);

    await tester.tap(find.byType(DropdownButtonFormField<SizeChart>));
    await settle(tester);

    for (final SizeChart chart in SizeChart.values) {
      expect(find.text(chart.title), findsWidgets);
    }
  });
}
