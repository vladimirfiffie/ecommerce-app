import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';

/// Price, with the struck-through original when the product is discounted.
class PriceText extends StatelessWidget {
  const PriceText({
    required this.product,
    super.key,
    this.style,
    this.compact = false,
  });

  final Product product;
  final TextStyle? style;

  /// Hides the original price — used where space is tight.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle priceStyle = (style ?? theme.textTheme.titleMedium)!
        .copyWith(fontWeight: FontWeight.w700);

    if (!product.isOnSale || compact) {
      return Text(formatPrice(product.price), style: priceStyle);
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: <Widget>[
        Text(formatPrice(product.price), style: priceStyle),
        Text(
          formatPrice(product.compareAtPrice!),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            decoration: TextDecoration.lineThrough,
            decorationColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
