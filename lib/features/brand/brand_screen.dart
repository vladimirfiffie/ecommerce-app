import '../../shared/widgets/adaptive_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/product_grid.dart';
import '../../shared/widgets/skeletons.dart';
import '../../state/app_providers.dart';
import '../../state/brand_provider.dart';
import '../../data/repositories/product_repository.dart';

/// Everything one brand sells, reached by tapping the brand on a product.
class BrandScreen extends ConsumerWidget {
  const BrandScreen({required this.brand, super.key});

  /// Brand name as it came off the route.
  final String brand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Catalog> catalog = ref.watch(catalogProvider);
    final BrandPage page = ref.watch(brandProvider(brand));
    final double gutter = Breakpoints.gutter(Breakpoints.of(context));

    return AdaptiveScreen(
      title: page.name,
      body: switch (catalog) {
        // The catalog is what the brand is derived from, so an empty page
        // during the load would read as "this brand sells nothing".
        AsyncLoading<Catalog>() => const _Skeleton(),
        AsyncError<Catalog>(:final Object error) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn’t load the shop',
          message: '$error',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(catalogProvider),
        ),
        _ =>
          page.isEmpty
              ? EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'Nothing from ${page.name}',
                  message:
                      'This brand has nothing in the shop right now. It may '
                      'have sold out or been discontinued.',
                  actionLabel: 'Browse the shop',
                  onAction: () => context.go(Routes.catalog),
                )
              : CustomScrollView(
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 22),
                        child: _BrandHeader(page: page),
                      ),
                    ),
                    ProductGrid(
                      products: page.products,
                      heroPrefix: 'brand',
                      sliver: true,
                      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 28),
                    ),
                  ],
                ),
      },
    );
  }
}

/// Who the brand is and how much of it there is.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.page});

  final BrandPage page;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double? rating = page.averageRating;
    final double? from = page.lowestPrice;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  page.name.characters.first.toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      page.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${page.count} ${page.count == 1 ? 'product' : 'products'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (rating != null)
                Pill(
                  label: '${rating.toStringAsFixed(1)} average',
                  icon: Icons.star_rounded,
                  background: theme.colorScheme.surface.withValues(alpha: 0.75),
                  foreground: theme.colorScheme.onSurface,
                ),
              if (from != null)
                Pill(
                  label: 'From ${formatPrice(from)}',
                  icon: Icons.sell_outlined,
                  background: theme.colorScheme.surface.withValues(alpha: 0.75),
                  foreground: theme.colorScheme.onSurface,
                ),
              if (page.onSaleCount > 0)
                Pill(
                  label: '${page.onSaleCount} on sale',
                  icon: Icons.local_offer_outlined,
                  background: AppTheme.accent,
                  foreground: Colors.white,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final double gutter = Breakpoints.gutter(Breakpoints.of(context));
    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 28),
      children: const <Widget>[
        SkeletonShimmer(
          child: SkeletonBox(height: 132, radius: AppTheme.radiusLg),
        ),
        SizedBox(height: 22),
        SkeletonShimmer(
          child: SkeletonBox(height: 220, radius: AppTheme.radiusMd),
        ),
      ],
    );
  }
}
