import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../data/models/order_line.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/app_providers.dart';
import '../../state/cart_provider.dart';
import '../../state/orders_provider.dart';
import 'orders_screen.dart' show OrderStatusPill;
import '../../shared/widgets/confirm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({
    required this.orderId,
    super.key,
    this.embedded = false,
  });

  final String orderId;

  /// Shown in a two-pane layout, where a back button would be meaningless.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Order? order = ref.watch(orderByIdProvider(orderId));
    // Status, tracker and the cancel/return actions all read the clock.
    ref.watch(orderClockProvider);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: AppL10n.of(context).orderNotFoundTitle,
          message: AppL10n.of(context).orderNotFoundMessage(orderId),
          actionLabel: AppL10n.of(context).orderAllOrders,
          onAction: () => context.go(Routes.orders),
        ),
      );
    }

    final List<OrderLine> items = ref.watch(orderItemsProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(order.id),
        automaticallyImplyLeading: !embedded,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          Row(
            children: <Widget>[
              // Both sides flex: "RETURN REQUESTED" is a much wider pill than
              // "SHIPPED", and a fixed Spacer overflowed a 360px header.
              Flexible(child: OrderStatusPill(status: order.status)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  AppL10n.of(context).orderPlacedOn(formatDate(order.placedAt)),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _Tracker(status: order.status, eta: order.estimatedDelivery),
          const SizedBox(height: 28),
          Text(
            AppL10n.of(context).orderItems,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final OrderLine item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: AppImage(
                      url: item.imageUrl,
                      fit: BoxFit.contain,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.displayNameIn(AppL10n.of(context)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          <String>[
                            'Qty ${item.quantity}',
                            if (item.variantLabel != null) item.variantLabel!,
                          ].join('  ·  '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatPrice(item.lineTotal),
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          const Divider(height: 28),
          _SummaryRow(
            label: AppL10n.of(context).summarySubtotal,
            value: formatPrice(order.subtotal),
          ),
          if (order.discount > 0)
            _SummaryRow(
              label: AppL10n.of(context).summaryDiscount,
              value: '−${formatPrice(order.discount)}',
            ),
          _SummaryRow(
            label: AppL10n.of(context).summaryShipping,
            value: order.shipping == 0
                ? AppL10n.of(context).summaryFree
                : formatPrice(order.shipping),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Text(
                AppL10n.of(context).summaryTotal,
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                formatPrice(order.total),
                style: order.creditApplied > 0
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge,
              ),
            ],
          ),
          if (order.creditApplied > 0) ...<Widget>[
            _SummaryRow(
              label: AppL10n.of(context).summaryStoreCredit,
              value: '−${formatPrice(order.creditApplied)}',
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Text(
                  AppL10n.of(context).orderCharged,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  formatPrice(order.cardCharged),
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ],
          const SizedBox(height: 26),
          Text(
            AppL10n.of(context).orderDelivery,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            order.shippingAddress,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (order.hasDeliveryInstructions) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  order.dropOff.icon,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    <String>[
                      order.dropOff.labelIn(AppL10n.of(context)),
                      if (order.deliveryNote.isNotEmpty) order.deliveryNote,
                    ].join('\n'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (order.giftWrapped || order.giftMessage.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              AppL10n.of(context).orderGift,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              <String>[
                if (order.giftWrapped) AppL10n.of(context).orderGiftWrapped,
                if (order.giftMessage.isNotEmpty) '“${order.giftMessage}”',
              ].join('\n'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            AppL10n.of(context).orderPayment,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            order.paymentLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 30),

          if (order.returnRequest case final ReturnRequest r) ...<Widget>[
            _ReturnBanner(order: order, request: r),
            const SizedBox(height: 14),
          ],

          if (order.canCancel) ...<Widget>[
            OutlinedButton.icon(
              onPressed: () => _cancel(context, ref, order),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              icon: const Icon(Icons.cancel_outlined, size: 20),
              label: Text(AppL10n.of(context).orderCancelAction),
            ),
            const SizedBox(height: 10),
          ],
          if (order.canReturn) ...<Widget>[
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.returnRequest(order.id)),
              icon: const Icon(Icons.assignment_return_outlined, size: 20),
              label: Text(
                AppL10n.of(context).orderReturnAction(order.returnDaysLeft),
              ),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.invoice(order.id)),
            icon: const Icon(Icons.receipt_outlined, size: 20),
            label: Text(AppL10n.of(context).orderViewReceipt),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: items.isEmpty
                ? null
                : () => _reorder(context, ref, items),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(AppL10n.of(context).orderBuyAgain),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, Order order) async {
    final bool yes = await confirmDestructive(
      context,
      title: AppL10n.of(context).confirmationCancelTitle,
      message: AppL10n.of(context).orderCancelMessage,
      confirmLabel: AppL10n.of(context).orderCancelConfirm,
      cancelLabel: AppL10n.of(context).orderCancelKeep,
    );
    if (!yes || !context.mounted) return;

    final bool ok = await ref.read(ordersProvider.notifier).cancel(order.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? AppL10n.of(context).orderCancelled
                : AppL10n.of(context).orderTooLateToCancel,
          ),
        ),
      );
  }

  /// Puts the order back in the bag.
  ///
  /// Unlike the rest of this screen, reorder goes to the live catalog on
  /// purpose: it's a new purchase, so it has to use today's price and stock
  /// rather than the snapshot of what this order cost. Anything since delisted
  /// can't be bought again, and the count of what was skipped is reported
  /// instead of quietly dropping it.
  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    List<OrderLine> items,
  ) async {
    final Catalog catalog = ref.read(catalogDataProvider);
    int unavailable = 0;

    for (final OrderLine item in items) {
      final Product? product = catalog.byId(item.productId);
      if (product == null || !product.inStock) {
        unavailable++;
        continue;
      }
      await ref
          .read(cartProvider.notifier)
          .add(
            product,
            size: item.size,
            color: _colorOn(product, item.colorName),
            quantity: item.quantity,
          );
    }
    if (!context.mounted) return;

    final int added = items.length - unavailable;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _reorderMessage(
              AppL10n.of(context),
              added: added,
              skipped: unavailable,
            ),
          ),
          action: added == 0
              ? null
              : SnackBarAction(
                  label: AppL10n.of(context).viewBag,
                  onPressed: () => context.go(Routes.cart),
                ),
        ),
      );
  }

  static String _reorderMessage(
    AppL10n l10n, {
    required int added,
    required int skipped,
  }) {
    if (added == 0) return l10n.reorderNoneAvailable(skipped);
    if (skipped == 0) return l10n.reorderAdded;
    return l10n.reorderPartial(added, skipped);
  }

  /// The variant color as the live product spells it, or null if that
  /// colorway has gone.
  static ProductColor? _colorOn(Product product, String? name) {
    if (name == null) return null;
    for (final ProductColor c in product.colors) {
      if (c.name == name) return c;
    }
    return null;
  }
}

/// Processing → Shipped → Delivered progress rail.
/// Shown in place of the delivery rail once an order is cancelled or
/// refunded — one clear statement rather than a progress bar going nowhere.
class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool refunded = status == OrderStatus.refunded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            refunded
                ? Icons.replay_circle_filled_rounded
                : Icons.cancel_outlined,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  status.labelIn(AppL10n.of(context)),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  refunded
                      ? AppL10n.of(context).orderRefundedNothingComing
                      : AppL10n.of(context).orderCancelledNothingComing,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tracker extends StatelessWidget {
  const _Tracker({required this.status, required this.eta});

  final OrderStatus status;
  final DateTime eta;

  /// Only the three stages a parcel actually passes through. Cancelled,
  /// returned and refunded are separate outcomes, not steps on this rail —
  /// including them made six labels that couldn't fit.
  static const List<OrderStatus> _stages = <OrderStatus>[
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // A cancelled or refunded order never travels, so drawing an empty
    // three-stage rail under "Arriving by ..." was actively misleading.
    if (status.isClosed) return _ClosedNotice(status: status);

    // A return keeps the rail — it did arrive — with the outcome above it.
    final int activeIndex = status == OrderStatus.returnRequested
        ? _stages.length - 1
        : _stages.indexOf(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(switch (status) {
            OrderStatus.delivered => AppL10n.of(context).orderStatusDelivered,
            OrderStatus.returnRequested => AppL10n.of(
              context,
            ).orderDeliveredReturnInProgress,
            _ => AppL10n.of(context).orderArrivingBy(formatDeliveryDate(eta)),
          }, style: theme.textTheme.titleSmall),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              for (int i = 0; i < _stages.length; i++) ...<Widget>[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= activeIndex
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHigh,
                  ),
                  child: i <= activeIndex
                      ? Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: theme.colorScheme.onPrimary,
                        )
                      : null,
                ),
                if (i < _stages.length - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i < activeIndex
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (final OrderStatus s in _stages)
                Text(
                  s.labelIn(AppL10n.of(context)),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _stages.indexOf(s) <= activeIndex
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status of an in-flight return, with a way to withdraw it.
class _ReturnBanner extends ConsumerWidget {
  const _ReturnBanner({required this.order, required this.request});

  final Order order;
  final ReturnRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool refunded = order.status == OrderStatus.refunded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                refunded
                    ? Icons.replay_circle_filled_rounded
                    : Icons.assignment_return_outlined,
                size: 20,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  refunded
                      ? AppL10n.of(context).orderStatusRefunded
                      : AppL10n.of(context).orderReturnInProgress,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                formatPrice(request.refundAmount),
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            <String>[
              request.reason.labelIn(AppL10n.of(context)),
              if (refunded)
                // A refund goes back the way it was paid, so an order
                // part-settled with credit gets part of it back there.
                order.creditApplied > 0
                    ? AppL10n.of(context).orderRefundedToCardAndCredit
                    : AppL10n.of(context).orderRefundedTo(order.paymentLabel)
              else
                AppL10n.of(context).orderRefundExpectedBy(
                  formatDeliveryDate(request.expectedRefundBy),
                ),
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (request.note.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text('“${request.note}”', style: theme.textTheme.bodySmall),
          ],
          if (!refunded) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () async {
                  await ref
                      .read(ordersProvider.notifier)
                      .cancelReturn(order.id);
                },
                child: Text(AppL10n.of(context).orderWithdrawReturn),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
