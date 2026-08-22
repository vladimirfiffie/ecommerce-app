import 'package:material_ui/material_ui.dart';

import '../../../data/models/product.dart';
import '../../../shared/widgets/product_card.dart';

/// Horizontally scrolling row of [ProductCard]s.
class ProductRail extends StatelessWidget {
  const ProductRail({
    required this.products,
    super.key,
    this.heroPrefix = 'rail',
    this.cardWidth = 168,
  });

  final List<Product> products;
  final String heroPrefix;
  final double cardWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 300,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.none,
      itemCount: products.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(width: 16),
      itemBuilder: (BuildContext context, int index) => ProductCard(
        product: products[index],
        width: cardWidth,
        heroPrefix: heroPrefix,
      ),
    ),
  );
}
