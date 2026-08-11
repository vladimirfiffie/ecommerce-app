import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product.dart';
import 'app_image.dart';
import 'favorite_button.dart';
import 'pill.dart';
import 'price_text.dart';
import 'rating_stars.dart';

/// Tall card used by the home rails and the catalog grid.
///
/// The image is wrapped in a [Hero] tagged `product-<id>-<heroPrefix>` so the
/// transition into the detail page works even when the same product appears in
/// two rails on one screen.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    super.key,
    this.width,
    this.heroPrefix = 'grid',
    this.selected = false,
    this.onTap,
  });

  final Product product;
  final double? width;
  final String heroPrefix;

  /// Marked as the current item in a two-pane layout.
  final bool selected;

  /// Overrides the default push-a-route behaviour.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => context.push(Routes.product(product.id)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Hero(
                      tag: 'product-${product.id}-$heroPrefix',
                      child: AppImage(
                        url: product.thumbnail,
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    if (selected)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _Badges(product: product),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: FavoriteButton(productId: product.id, size: 18),
                    ),
                    if (!product.inStock)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          child: Center(
                            child: Pill(
                              label: 'SOLD OUT',
                              background: theme.colorScheme.inverseSurface,
                              foreground: theme.colorScheme.onInverseSurface,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.brand.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              RatingStars(
                rating: product.rating,
                size: 13,
                reviewCount: product.reviewCount,
              ),
              const SizedBox(height: 6),
              PriceText(product: product, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: <Widget>[
        if (product.isOnSale)
          Pill(
            label: '-${product.discountPercent}%',
            background: AppTheme.accent,
            foreground: Colors.white,
          ),
        if (product.isNew)
          Pill(
            label: 'NEW',
            background: theme.colorScheme.inverseSurface,
            foreground: theme.colorScheme.onInverseSurface,
          ),
      ],
    );
  }
}

/// Horizontal variant used in the cart, wishlist list mode and order history.
class ProductRow extends StatelessWidget {
  const ProductRow({
    required this.product,
    super.key,
    this.trailing,
    this.subtitle,
    this.onTap,
    this.heroPrefix = 'row',
  });

  final Product product;
  final Widget? trailing;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap ?? () => context.push(Routes.product(product.id)),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 88,
              height: 88,
              child: Hero(
                tag: 'product-${product.id}-$heroPrefix',
                child: AppImage(
                  url: product.thumbnail,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    product.brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 4),
                    DefaultTextStyle.merge(
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      child: subtitle!,
                    ),
                  ],
                  const SizedBox(height: 8),
                  PriceText(product: product),
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
