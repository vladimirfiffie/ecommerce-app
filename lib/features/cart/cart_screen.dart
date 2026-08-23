import '../favorites/widgets/saved_for_later_section.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../../shared/widgets/messages.dart';
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
import '../../data/repositories/product_repository.dart';
import '../../shared/widgets/catalog_unavailable.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/quantity_stepper.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/app_providers.dart';
import '../../state/cart_provider.dart';
import '../../state/saved_for_later_provider.dart';
import 'widgets/order_summary.dart';
import 'widgets/promo_field.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppL10n l10n = AppL10n.of(context);
    final List<CartItem> items = ref.watch(cartItemsProvider);
    final CartSummary summary = ref.watch(cartSummaryProvider);
    final bool wide = Breakpoints.of(context).isWide;

    // Lines are stored as ids, so an unresolved bag and an empty one look
    // identical from here. They aren't: one of them still has the shopper's
    // things in it, and the tab badge is already counting them.
    final List<CartEntry> stored = ref.watch(cartProvider);
    final AsyncValue<Catalog> catalog = ref.watch(catalogProvider);
    final bool unresolved = items.isEmpty && stored.isNotEmpty;
    final List<CartEntry> unavailable = ref.watch(
      unavailableCartEntriesProvider,
    );
    final List<CartItem> saved = ref.watch(savedForLaterItemsProvider);

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
                      l10n.bagTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  if (stored.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClear(context, ref),
                      child: Text(l10n.bagClear),
                    ),
                ],
              ),
            ),
            if (unresolved && catalog.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (unresolved)
              Expanded(
                child: CatalogUnavailable(
                  title: AppL10n.of(context).couldNotLoadBag,
                ),
              )
            else if (items.isEmpty)
              Expanded(
                child: saved.isEmpty
                    ? EmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title: l10n.bagEmptyTitle,
                        message: l10n.bagEmptyMessage,
                        actionLabel: l10n.bagEmptyAction,
                        onAction: () => context.go(Routes.catalog),
                      )
                    // An empty bag with things put aside is not an empty
                    // screen: what was saved is the reason to come back.
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        children: const <Widget>[SavedForLaterSection()],
                      ),
              )
            else ...<Widget>[
              if (unavailable.isNotEmpty)
                UnavailableLinesNotice(
                  count: unavailable.length,
                  onRemove: () => ref
                      .read(cartProvider.notifier)
                      .removeAll(unavailable.map((CartEntry e) => e.lineId)),
                ),
              if (wide) ...<Widget>[
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
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  24,
                                ),
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
                                AppL10n.of(context).bagCheckoutWithTotal(
                                  formatPrice(summary.total),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...<Widget>[
                if (!summary.hasFreeShipping)
                  _FreeShippingBar(summary: summary),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    children: <Widget>[
                      for (int i = 0; i < items.length; i++)
                        _CartLine(item: items[i], index: i)
                            .animate(delay: (i * 45).ms)
                            .fadeIn(duration: 240.ms)
                            .moveX(
                              begin: 16,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
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
                      const SavedForLaterSection(),
                    ],
                  ),
                ),
                _CheckoutBar(summary: summary),
              ],
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
        title: Text(AppL10n.of(context).bagConfirmClearTitle),
        content: Text(AppL10n.of(context).bagConfirmClearMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppL10n.of(context).bagConfirmKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppL10n.of(context).bagConfirmEmpty),
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
                  AppL10n.of(context).bagFreeShippingNudge(
                    formatPrice(summary.amountToFreeShipping),
                  ),
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
        showMessage(
          context,
          AppL10n.of(context).bagRemovedItem(item.product.name),
          action: AppL10n.of(context).undo,
          onAction: () => cart.restore(removed, index),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: AdaptiveCard(
          child: ProductRow(
            product: item.product,
            heroPrefix: 'cart',
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (item.variantLabel != null) Text(item.variantLabel!),
                // Not a destructive action, so it sits quietly under the
                // line rather than competing with the bin on the swipe.
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => ref
                        .read(savedForLaterProvider.notifier)
                        .saveForLater(item.entry),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.bookmark_border_rounded, size: 17),
                    label: Text(AppL10n.of(context).bagSaveForLater),
                  ),
                ),
              ],
            ),
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
                  // Here the bin is honest: decrementing the last one takes
                  // the line out of the bag.
                  removeAtMin: true,
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
                    AppL10n.of(context).orderItemCount(summary.itemCount),
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
                  label: Text(AppL10n.of(context).bagCheckout),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Things put aside, under the bag they came out of.
///
/// Draws nothing at all when the list is empty — an empty section here would
/// be a permanent invitation to a feature nobody has used yet.
