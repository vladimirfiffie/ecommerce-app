import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/product.dart';

/// Which chart a product needs, inferred from the sizes it actually offers.
enum SizeChart {
  apparel,
  mensShoes,
  womensShoes;

  /// Null when the product has no sizes worth explaining.
  static SizeChart? forProduct(Product product) {
    if (product.sizes.isEmpty) return null;
    if (product.sizes.first.contains(RegExp('[A-Za-z]'))) {
      return SizeChart.apparel;
    }
    // Numeric sizes: the men's range starts at 7, the women's at 5.
    final int? smallest = int.tryParse(product.sizes.first);
    if (smallest == null) return null;
    return smallest >= 7 ? SizeChart.mensShoes : SizeChart.womensShoes;
  }

  String get title => switch (this) {
    SizeChart.apparel => 'Clothing sizes',
    SizeChart.mensShoes => 'Men’s shoe sizes',
    SizeChart.womensShoes => 'Women’s shoe sizes',
  };

  List<String> get columns => switch (this) {
    SizeChart.apparel => <String>['Size', 'Chest (in)', 'Waist (in)'],
    _ => <String>['US', 'EU', 'Foot (cm)'],
  };

  List<List<String>> get rows => switch (this) {
    SizeChart.apparel => const <List<String>>[
      <String>['XS', '33–35', '27–28'],
      <String>['S', '35–37', '29–30'],
      <String>['M', '38–40', '31–33'],
      <String>['L', '41–43', '34–36'],
      <String>['XL', '44–46', '37–39'],
    ],
    SizeChart.mensShoes => const <List<String>>[
      <String>['7', '40', '25.0'],
      <String>['8', '41', '26.0'],
      <String>['9', '42', '27.0'],
      <String>['10', '43', '28.0'],
      <String>['11', '44', '29.0'],
      <String>['12', '45', '30.0'],
    ],
    SizeChart.womensShoes => const <List<String>>[
      <String>['5', '35', '22.0'],
      <String>['6', '36', '23.0'],
      <String>['7', '37', '23.5'],
      <String>['8', '38', '24.5'],
      <String>['9', '39', '25.5'],
      <String>['10', '40', '26.5'],
    ],
  };

  String get tip => switch (this) {
    SizeChart.apparel =>
      'Measure around the fullest part of your chest, keeping the tape level. '
          'Between sizes? Size up for a relaxed fit.',
    _ =>
      'Measure your foot from heel to longest toe, standing, in the evening — '
          'feet swell during the day. Between sizes? Size up.',
  };
}

Future<void> showSizeGuideSheet(BuildContext context, Product product) {
  final SizeChart? chart = SizeChart.forProduct(product);
  if (chart == null) return Future<void>.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => SizeGuideSheet(chart: chart),
  );
}

class SizeGuideSheet extends StatefulWidget {
  const SizeGuideSheet({required this.chart, super.key});

  /// The chart the product itself implies — where the sheet opens.
  final SizeChart chart;

  @override
  State<SizeGuideSheet> createState() => _SizeGuideSheetState();
}

class _SizeGuideSheetState extends State<SizeGuideSheet> {
  late SizeChart _chart = widget.chart;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SizeChart chart = _chart;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // The product picks the chart it opens on, but a shopper buying a
            // gift is looking for a different one — so every chart is here,
            // rather than only the one this product happens to imply.
            DropdownButtonFormField<SizeChart>(
              initialValue: chart,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Size chart',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: <DropdownMenuItem<SizeChart>>[
                for (final SizeChart option in SizeChart.values)
                  DropdownMenuItem<SizeChart>(
                    value: option,
                    child: Text(option.title),
                  ),
              ],
              onChanged: (SizeChart? next) {
                if (next != null) setState(() => _chart = next);
              },
            ),
            const SizedBox(height: 16),
            // Charts are wide; let them scroll rather than squeeze.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                key: ValueKey<SizeChart>(chart),
                headingRowHeight: 40,
                dataRowMinHeight: 38,
                dataRowMaxHeight: 44,
                columns: <DataColumn>[
                  for (final String c in chart.columns)
                    DataColumn(
                      label: Text(c, style: theme.textTheme.labelLarge),
                    ),
                ],
                rows: <DataRow>[
                  for (final List<String> row in chart.rows)
                    DataRow(
                      cells: <DataCell>[
                        for (final String cell in row) DataCell(Text(cell)),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.straighten_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      chart.tip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
