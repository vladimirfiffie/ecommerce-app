import 'package:material_ui/material_ui.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/semantic_labels.dart';
import '../../data/models/product.dart';
import '../../l10n/generated/app_localizations.dart';

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

    // Read out, the two prices are indistinguishable — the strikethrough is
    // the only thing marking one as the old one, and that doesn't survive
    // being spoken.
    return Semantics(
      label: priceLabel(product, AppL10n.of(context)),
      excludeSemantics: true,
      child: Wrap(
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
      ),
    );
  }
}
