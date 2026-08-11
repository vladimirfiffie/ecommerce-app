import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeletons.dart';
import '../../state/app_providers.dart';
import '../../state/catalog_filter_provider.dart';
import 'widgets/hero_carousel.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/product_rail.dart';
import '../../shared/widgets/product_grid.dart';
import '../../core/layout/breakpoints.dart';
import '../../shared/widgets/nova_refresh.dart';
import 'widgets/for_you_card.dart';
import 'widgets/deal_countdown.dart';
import '../../state/deals_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Catalog> catalog = ref.watch(catalogProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: NovaRefresh(
          child: CustomScrollView(
            slivers: <Widget>[
              const HomeAppBar(),
              ...switch (catalog) {
                AsyncData<Catalog>(value: final Catalog data) => _loaded(
                  context,
                  ref,
                  data,
                ),
                AsyncError<Catalog>(:final Object error) => <Widget>[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Couldn’t load the shop',
                      message: '$error',
                      actionLabel: 'Try again',
                      onAction: () => ref.invalidate(catalogProvider),
                    ),
                  ),
                ],
                _ => _skeleton(),
              },
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _skeleton() => <Widget>[
    const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: SkeletonShimmer(
          child: SkeletonBox(height: 176, radius: AppTheme.radiusLg),
        ),
      ),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 28)),
    const SliverToBoxAdapter(child: ProductRailSkeleton()),
    const SliverToBoxAdapter(child: SizedBox(height: 28)),
    const SliverToBoxAdapter(child: ProductRailSkeleton()),
  ];

  List<Widget> _loaded(BuildContext context, WidgetRef ref, Catalog catalog) {
    final List<Product> featured = catalog.featured;
    final List<Product> newArrivals = catalog.newArrivals;
    final List<Product> deals = ref.watch(dailyDealsProvider);
    final List<Product> popular = _popular(catalog);

    void browse(String? categoryId) {
      ref.read(catalogFilterProvider.notifier).reset();
      ref.read(catalogFilterProvider.notifier).setCategory(categoryId);
      context.go(Routes.catalog);
    }

    return <Widget>[
      SliverToBoxAdapter(
        child: HeroCarousel(
          products: featured.isEmpty
              ? catalog.products.take(4).toList()
              : featured.take(5).toList(),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 22)),
      // Everything the app already knows about you. Draws nothing when
      // there's nothing to say.
      const SliverToBoxAdapter(child: ForYouCard()),
      const SliverToBoxAdapter(child: SizedBox(height: 26)),
      if (deals.isNotEmpty) ...<Widget>[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Today’s deals',
            // A real deadline: the selection rotates at local midnight.
            subtitleWidget: DealCountdown(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            actionLabel: 'See all',
            onAction: () {
              ref.read(catalogFilterProvider.notifier).reset();
              ref.read(catalogFilterProvider.notifier).setOnSaleOnly(true);
              ref
                  .read(catalogFilterProvider.notifier)
                  .setSort(SortOption.biggestDiscount);
              context.go(Routes.catalog);
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(
          child: ProductRail(products: deals, heroPrefix: 'deals'),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
      if (newArrivals.isNotEmpty) ...<Widget>[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'New arrivals',
            subtitle: 'Fresh in this week',
            actionLabel: 'See all',
            onAction: () => browse(null),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        // A grid rather than a third side-scroller: stacked rails all read
        // the same, and a rail hides most of what's in it.
        ProductGrid(
          products: newArrivals.take(4).toList(),
          heroPrefix: 'new',
          sliver: true,
          padding: EdgeInsets.symmetric(
            horizontal: Breakpoints.gutter(Breakpoints.of(context)),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
      const SliverToBoxAdapter(
        child: SectionHeader(title: 'Popular right now'),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      ProductGrid(
        products: popular,
        heroPrefix: 'popular',
        sliver: true,
        padding: EdgeInsets.fromLTRB(
          Breakpoints.gutter(Breakpoints.of(context)),
          0,
          Breakpoints.gutter(Breakpoints.of(context)),
          28,
        ),
      ),
    ];
  }

  List<Product> _popular(Catalog catalog) {
    final List<Product> pool = <Product>[...catalog.products]
      ..sort((Product a, Product b) {
        final int byRating = b.rating.compareTo(a.rating);
        return byRating != 0
            ? byRating
            : b.reviewCount.compareTo(a.reviewCount);
      });
    return pool.take(8).toList();
  }
}
