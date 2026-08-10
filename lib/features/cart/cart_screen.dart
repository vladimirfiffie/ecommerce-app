import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_entry.dart';
import '../../data/models/cart_item.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/quantity_stepper.dart';
import '../../state/cart_provider.dart';
import 'widgets/order_summary.dart';
import 'widgets/promo_field.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<CartItem> items = ref.watch(cartItemsProvider);
    final CartSummary summary = ref.watch(cartSummaryProvider);
    final bool wide = Breakpoints.of(context).isWide;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Your bag',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  if (items.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClear(context, ref),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            if (items.isEmpty)
              Expanded(
                child: EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your bag is empty',
                  message:
                      'Once you add something you like, it’ll show up here.',
                  actionLabel: 'Start shopping',
                  onAction: () => context.go(Routes.catalog),
                ),
              )
            else if (wide) ...<Widget>[
              // Wide windows put the summary in a sticky side panel so the
              // total and checkout stay in view while the list scrolls.
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: <Widget>[
                          if (!summary.hasFreeShipping)
                            _FreeShippingBar(summary: summary),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                              children: <Widget>[
                                for (int i = 0; i < items.length; i++)
                                  _CartLine(item: items[i], index: i)
                                      .animate(delay: (i * 45).ms)
                                      .fadeIn(duration: 240.ms),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 2,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        children: <Widget>[
                          const PromoField(),
                          const SizedBox(height: 20),
                          const OrderSummary(),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => context.push(Routes.checkout),
                            icon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                            ),
                            label: Text(
                              'Checkout · ${formatPrice(summary.total)}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...<Widget>[
              if (!summary.hasFreeShipping) _FreeShippingBar(summary: summary),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  children: <Widget>[
                    for (int i = 0; i < items.length; i++)
                      _CartLine(item: items[i], index: i)
                          .animate(delay: (i * 45).ms)
                          .fadeIn(duration: 240.ms)
                          .moveX(begin: 16, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: PromoField(),
                    ),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: OrderSummary(),
                    ),
                  ],
                ),
              ),
              _CheckoutBar(summary: summary),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Empty your bag?'),
        content: const Text('This removes every item. It can’t be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep them'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Empty bag'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(cartProvider.notifier).clear();
      ref.read(appliedPromoProvider.notifier).clear();
    }
  }
}

/// "Spend $12 more for free shipping" progress nudge.
class _FreeShippingBar extends StatelessWidget {
  const _FreeShippingBar({required this.summary});

  final CartSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double progress =
        1 - (summary.amountToFreeShipping / Pricing.freeShippingThreshold);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Add ${formatPrice(summary.amountToFreeShipping)} for free shipping',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.item, required this.index});

  final CartItem item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final CartNotifier cart = ref.read(cartProvider.notifier);

    return Dismissible(
      key: ValueKey<String>(item.lineId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) {
        final CartEntry removed = item.entry;
        cart.remove(item.lineId);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Removed ${item.product.name}'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => cart.restore(removed, index),
              ),
            ),
          );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Card(
          child: ProductRow(
            product: item.product,
            heroPrefix: 'cart',
            subtitle: item.variantLabel == null
                ? null
                : Text(item.variantLabel!),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  formatPrice(item.lineTotal),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 20),
                QuantityStepper(
                  quantity: item.quantity,
                  dense: true,
                  max: item.product.stock.clamp(1, 99),
                  onDecrement: () => cart.decrement(item.lineId),
                  onIncrement: () => cart.increment(item.lineId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.summary});

  final CartSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
                    '${summary.itemCount} ${summary.itemCount == 1 ? 'item' : 'items'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatPrice(summary.total),
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push(Routes.checkout),
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: const Text('Checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
