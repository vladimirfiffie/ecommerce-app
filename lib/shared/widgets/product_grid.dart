import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;
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
    this.selectedId,
    this.onSelect,
  });

  final List<Product> products;
  final String heroPrefix;
  final EdgeInsets? padding;

  /// Emit a sliver instead of a scrollable box.
  final bool sliver;

  /// Highlighted card in a two-pane layout.
  final String? selectedId;

  /// When set, tapping selects instead of pushing a route.
  final ValueChanged<String>? onSelect;

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

  Widget _item(BuildContext context, int index) {
    final Product product = products[index];
    return ProductCard(
      product: product,
      heroPrefix: heroPrefix,
      selected: product.id == selectedId,
      onTap: onSelect == null ? null : () => onSelect!(product.id),
    ).animate(delay: (index % 8 * 35).ms).fadeIn(duration: 240.ms);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pad = padding ?? EdgeInsets.zero;

    // Measure the space this grid actually gets, not the whole window: in a
    // two-pane layout the list column is far narrower than the screen, and
    // sizing from MediaQuery packs in columns that don't fit.
    if (sliver) {
      return SliverPadding(
        padding: pad,
        sliver: SliverLayoutBuilder(
          builder: (BuildContext context, SliverConstraints constraints) =>
              SliverGrid.builder(
                gridDelegate: _delegate(
                  constraints.crossAxisExtent + pad.horizontal,
                ),
                itemCount: products.length,
                itemBuilder: _item,
              ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          GridView.builder(
            padding: pad,
            gridDelegate: _delegate(constraints.maxWidth),
            itemCount: products.length,
            itemBuilder: _item,
          ),
    );
  }
}
