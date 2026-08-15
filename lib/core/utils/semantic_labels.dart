import '../../data/models/product.dart';
import '../../l10n/generated/app_localizations.dart';
import 'formatters.dart';

/// What a screen reader should say for things that are drawn rather than
/// written: stars, struck-through prices, a card built out of six fragments.
///
/// Kept together so the spoken wording stays consistent between the grid, the
/// product page and the bag.

/// `$25.00`, or `$25.00, reduced from $40.00, 38% off` when discounted.
///
/// Drawn, the old price is a struck-through number beside the new one; read
/// out, that's just two prices in a row with nothing to say which is which.
String priceLabel(Product product, AppL10n l10n) {
  if (!product.isOnSale) return formatPrice(product.price);
  return l10n.priceReducedFrom(
    formatPrice(product.price),
    formatPrice(product.compareAtPrice!),
    product.discountPercent,
  );
}

/// `Rated 4.5 out of 5 from 42 reviews`.
String ratingLabel(double rating, AppL10n l10n, [int? reviewCount]) {
  final String value = rating.toStringAsFixed(1);
  return reviewCount == null
      ? l10n.ratingOutOfFive(value)
      : l10n.ratingOutOfFiveWithReviews(value, reviewCount);
}

/// The whole card as one sentence, so a card is one swipe rather than six.
String productSummary(Product product, AppL10n l10n) => <String>[
  product.brand,
  product.name,
  priceLabel(product, l10n),
  ratingLabel(product.rating, l10n, product.reviewCount),
  if (!product.inStock)
    l10n.stockSoldOut
  else if (product.isLowStock)
    l10n.stockOnlyLeft(product.stock),
  if (product.isNew) l10n.badgeNew,
].join('. ');
