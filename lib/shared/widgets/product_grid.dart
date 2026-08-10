import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/layout/breakpoints.dart';
import '../../data/models/product.dart';
import 'product_card.dart';

/// Product grid whose column count follows the window width.
///
/// Card proportions are fixed, so the delegate derives a tile height from the
/// measured column width instead of relying on a hardcoded aspect ratio that
/// only holds at phone widths.
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    required this.products,
    required this.heroPrefix,
    super.key,
    this.padding,
    this.sliver = false,
  });

  final List<Product> products;
  final String heroPrefix;
  final EdgeInsets? padding;

  /// Emit a sliver instead of a scrollable box.
  final bool sliver;

  /// Space the card needs below its square image: brand, name (2 lines),
  /// rating and price, with a little headroom for larger text scales.
  static const double _captionHeight = 128;
  static const double _spacing = 20;

  SliverGridDelegate _delegate(double width) {
    final EdgeInsets pad = padding ?? EdgeInsets.zero;
    final int columns = Breakpoints.gridColumns(width);
    final double available = width - pad.horizontal - _spacing * (columns - 1);
    final double tileWidth = (available / columns).clamp(120.0, 400.0);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: _spacing + 4,
      crossAxisSpacing: _spacing,
      // Image is square, so the tile is that plus room for the caption.
      mainAxisExtent: tileWidth + _captionHeight,
    );
  }

  Widget _item(BuildContext context, int index) => ProductCard(
    product: products[index],
    heroPrefix: heroPrefix,
  ).animate(delay: (index % 8 * 35).ms).fadeIn(duration: 240.ms);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final EdgeInsets pad = padding ?? EdgeInsets.zero;

    if (sliver) {
      return SliverPadding(
        padding: pad,
        sliver: SliverGrid.builder(
          gridDelegate: _delegate(width),
          itemCount: products.length,
          itemBuilder: _item,
        ),
      );
    }
    return GridView.builder(
      padding: pad,
      gridDelegate: _delegate(width),
      itemCount: products.length,
      itemBuilder: _item,
    );
  }
}
