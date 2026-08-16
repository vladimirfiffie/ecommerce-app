import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/favorite_button.dart';
import '../../shared/widgets/pill.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/quantity_stepper.dart';
import '../../shared/widgets/rating_stars.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/app_providers.dart';
import '../../state/cart_provider.dart';
import '../../state/catalog_filter_provider.dart';
import 'widgets/image_gallery.dart';
import 'widgets/reviews_section.dart';
import 'widgets/specs_section.dart';
import 'widgets/variant_selector.dart';
import '../../state/haptics_provider.dart';
import 'package:haptic_kit/haptic_kit.dart';
import 'widgets/size_guide_sheet.dart';
import 'widgets/questions_section.dart';
import '../../state/alerts_provider.dart';
import '../home/widgets/deal_countdown.dart';
import '../../state/deals_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    required this.productId,
    super.key,
    this.embedded = false,
  });

  final String productId;

  /// Rendered inside a two-pane layout rather than pushed as a route, so
  /// there is nothing to go back to and the back affordance is dropped.
  final bool embedded;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  /// Wiggles the buy bar when a required variant hasn't been chosen.
  final GlobalKey<HapticShakeState> _shakeKey = GlobalKey<HapticShakeState>();

  String? _size;
  ProductColor? _color;
  int _quantity = 1;
  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    // Record the visit once the first frame is up so it lands in the
    // "recently viewed" rail on the way back.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recentlyViewedProvider.notifier).record(widget.productId);
    });
  }

  Future<void> _addToCart(Product product) async {
    if (product.sizes.isNotEmpty && _size == null) {
      _nudge('Pick a size first');
      return;
    }
    if (product.colors.isNotEmpty && _color == null) {
      _nudge('Pick a color first');
      return;
    }

    // Fire-and-forget: haptics must never gate (or fail) the cart write.
    unawaited(ref.read(hapticsProvider).impact(HapticImpactStyle.medium));
    await ref
        .read(cartProvider.notifier)
        .add(product, size: _size, color: _color, quantity: _quantity);
    unawaited(
      ref.read(hapticsProvider).notification(HapticNotificationStyle.success),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Added ${product.name} to your bag'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View bag',
            onPressed: () => context.go(Routes.cart),
          ),
        ),
      );
  }

  void _nudge(String message) {
    unawaited(
      ref.read(hapticsProvider).notification(HapticNotificationStyle.warning),
    );
    _shakeKey.currentState?.shake();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<Catalog> catalogAsync = ref.watch(catalogProvider);
    final Product? product = catalogAsync.value?.byId(widget.productId);

    if (catalogAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Product unavailable',
          message: 'This item is no longer in the catalog.',
          actionLabel: 'Back to shop',
          onAction: () => context.go(Routes.catalog),
        ),
      );
    }

    final List<Product> related = catalogAsync.value!.related(
      product,
      limit: 8,
    );

    // An embedded pane is already narrow, however wide the window is —
    // reading the window here would nest a second two-pane layout inside the
    // first, complete with its own back button.
    final bool wide = !widget.embedded && Breakpoints.of(context).isWide;

    // On a wide window the gallery gets its own fixed pane on the left and
    // the details scroll independently on the right; the phone layout keeps
    // the collapsing app bar.
    if (wide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: ImageGallery(
                        images: product.images,
                        videos: product.videos,
                        heroTag: 'product-${product.id}-catalog',
                      ),
                    ),
                    Positioned(top: 4, left: 4, child: _CircleBackButton()),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 6,
                child: CustomScrollView(
                  slivers: <Widget>[
                    SliverToBoxAdapter(child: _details(context, product)),
                    SliverToBoxAdapter(child: ReviewsSection(product: product)),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    SliverToBoxAdapter(
                      child: QuestionsSection(product: product),
                    ),
                    if (related.isNotEmpty) ...<Widget>[
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      const SliverToBoxAdapter(
                        child: SectionHeader(title: 'You might also like'),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      SliverToBoxAdapter(child: _relatedRail(related)),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buyBar(ref, product),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 420,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            leading: widget.embedded ? null : const _CircleBackButton(),
            automaticallyImplyLeading: !widget.embedded,
            actions: <Widget>[
              _CircleAction(
                icon: Icons.ios_share_rounded,
                tooltip: 'Share',
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Check out ${product.name} by ${product.brand} '
                        'on Aster — ${formatPrice(product.price)}\n'
                        '${deepLinkForProduct(product.id)}',
                    subject: product.name,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: FavoriteButton(productId: product.id, size: 20),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ImageGallery(
                images: product.images,
                videos: product.videos,
                heroTag: 'product-${product.id}-catalog',
              ),
            ),
          ),
          SliverToBoxAdapter(child: _details(context, product)),
          SliverToBoxAdapter(child: ReviewsSection(product: product)),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(child: QuestionsSection(product: product)),
          if (related.isNotEmpty) ...<Widget>[
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'You might also like'),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _relatedRail(related)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      bottomNavigationBar: _buyBar(ref, product),
    );
  }

  /// Everything below the gallery: title, price, variants, description.
  Widget _details(BuildContext context, Product product) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // Through to everything else this brand sells.
              Flexible(
                child: InkWell(
                  onTap: () => context.push(Routes.brand(product.brand)),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            product.brand.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (product.isOnSale)
                Pill(
                  label: 'SAVE ${product.discountPercent}%',
                  background: AppTheme.accent,
                  foreground: Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(product.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Flexible(
                child: RatingStars(
                  rating: product.rating,
                  reviewCount: product.reviewCount,
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              _StockLabel(product: product),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                formatPrice(product.price),
                style: theme.textTheme.headlineMedium,
              ),
              if (product.isOnSale) ...<Widget>[
                const SizedBox(width: 10),
                Text(
                  formatPrice(product.compareAtPrice!),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),

          // Only when this product is in today's rotating selection. The
          // countdown is about that listing ending, not the price changing —
          // the discount itself doesn't expire at midnight.
          if (ref.watch(dailyDealsProvider).contains(product)) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                // Both halves flex: at 360dp with a large text scale the
                // label plus "Ends in 12h 34m" is wider than the column, and
                // a fixed pair overflowed the row rather than shrinking.
                Flexible(
                  child: Text(
                    'In today’s deals · ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: DealCountdown(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (product.sizes.isNotEmpty) ...<Widget>[
            SizeSelector(
              sizes: product.sizes,
              selected: _size,
              onSelected: (String value) => setState(() => _size = value),
            ),
            if (SizeChart.forProduct(product) != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => showSizeGuideSheet(context, product),
                  icon: const Icon(Icons.straighten_rounded, size: 18),
                  label: const Text('Size guide'),
                ),
              ),
            const SizedBox(height: 22),
          ],
          if (product.colors.isNotEmpty) ...<Widget>[
            ColorSelector(
              colors: product.colors,
              selected: _color,
              onSelected: (ProductColor value) =>
                  setState(() => _color = value),
            ),
            const SizedBox(height: 22),
          ],
          Row(
            children: <Widget>[
              Text('Quantity', style: theme.textTheme.titleSmall),
              const Spacer(),
              QuantityStepper(
                quantity: _quantity,
                max: product.stock.clamp(1, 99),
                onDecrement: () =>
                    setState(() => _quantity = (_quantity - 1).clamp(1, 99)),
                onIncrement: () => setState(
                  () => _quantity = (_quantity + 1).clamp(
                    1,
                    product.stock.clamp(1, 99),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text('Description', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Text(
              product.description,
              maxLines: _descriptionExpanded ? null : 3,
              overflow: _descriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (product.description.length > 130)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(
                  () => _descriptionExpanded = !_descriptionExpanded,
                ),
                child: Text(_descriptionExpanded ? 'Show less' : 'Read more'),
              ),
            ),
          const SizedBox(height: 26),
          SpecsSection(product: product),
          const SizedBox(height: 20),
          if (!product.inStock) ...<Widget>[
            const SizedBox(height: 16),
            _notifyMeButton(product),
          ],
          const _DeliveryPerks(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _relatedRail(List<Product> related) => SizedBox(
    height: 300,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: related.length,
      separatorBuilder: (BuildContext c, int i) => const SizedBox(width: 16),
      itemBuilder: (BuildContext context, int index) => ProductCard(
        product: related[index],
        width: 168,
        heroPrefix: 'related',
      ).animate(delay: (index * 40).ms).fadeIn(duration: 240.ms),
    ),
  );

  /// Sold-out products get a watch button instead of a dead "Add to bag".
  Widget _notifyMeButton(Product product) {
    final bool watching = ref.watch(isWatchingStockProvider(product.id));
    return OutlinedButton.icon(
      onPressed: () async {
        final bool added = await ref
            .read(stockWatchProvider.notifier)
            .toggle(product.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                added
                    ? 'We’ll let you know when it’s back'
                    : 'Stopped watching this item',
              ),
            ),
          );
      },
      icon: Icon(
        watching
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        size: 20,
      ),
      label: Text(watching ? 'Watching for restock' : 'Notify me when back'),
    );
  }

  Widget _buyBar(WidgetRef ref, Product product) => HapticShake(
    key: _shakeKey,
    haptics: ref.watch(hapticsProvider).isOn(HapticChannel.notifications),
    child: _BuyBar(
      product: product,
      quantity: _quantity,
      onAdd: () => _addToCart(product),
    ),
  );
}

/// Back chevron on a translucent disc, legible over product photography.
class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton();

  @override
  Widget build(BuildContext context) => _CircleAction(
    icon: Icons.arrow_back_rounded,
    tooltip: 'Back',
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.home);
      }
    },
  );
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          iconSize: 20,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _StockLabel extends StatelessWidget {
  const _StockLabel({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (!product.inStock) {
      return Pill(
        label: 'SOLD OUT',
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
      );
    }
    if (product.isLowStock) {
      return Text(
        'Only ${product.stock} left',
        style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.accent),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.check_circle_rounded,
          size: 15,
          color: AppTheme.success,
        ),
        const SizedBox(width: 5),
        Text(
          'In stock',
          style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.success),
        ),
      ],
    );
  }
}

class _DeliveryPerks extends StatelessWidget {
  const _DeliveryPerks();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime eta = DateTime.now().add(const Duration(days: 4));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: <Widget>[
          _PerkRow(
            icon: Icons.local_shipping_outlined,
            title: 'Free delivery over \$75',
            subtitle: 'Arrives by ${formatDeliveryDate(eta)}',
          ),
          const SizedBox(height: 14),
          const _PerkRow(
            icon: Icons.autorenew_rounded,
            title: '30-day free returns',
            subtitle: 'No questions asked',
          ),
          const SizedBox(height: 14),
          const _PerkRow(
            icon: Icons.verified_user_outlined,
            title: '2-year warranty',
            subtitle: 'Covered against defects',
          ),
        ],
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 21, color: theme.colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleSmall),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BuyBar extends StatelessWidget {
  const _BuyBar({
    required this.product,
    required this.quantity,
    required this.onAdd,
  });

  final Product product;
  final int quantity;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double total = product.price * quantity;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(formatPrice(total), style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: FilledButton.icon(
                  onPressed: product.inStock ? onAdd : null,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                  label: Text(product.inStock ? 'Add to bag' : 'Sold out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
