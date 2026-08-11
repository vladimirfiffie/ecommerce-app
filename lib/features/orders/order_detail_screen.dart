import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/cart_provider.dart';
import '../../state/orders_provider.dart';
import 'orders_screen.dart' show OrderStatusPill;

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Order? order = ref.watch(orderByIdProvider(orderId));

    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Order not found',
          message: 'We couldn’t find order $orderId.',
          actionLabel: 'All orders',
          onAction: () => context.go(Routes.orders),
        ),
      );
    }

    final List<CartItem> items = ref.watch(orderItemsProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text(order.id)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          Row(
            children: <Widget>[
              OrderStatusPill(status: order.status),
              const Spacer(),
              Text(
                'Placed ${formatDate(order.placedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _Tracker(status: order.status, eta: order.estimatedDelivery),
          const SizedBox(height: 28),
          Text('Items', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final CartItem item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: AppImage(
                      url: item.product.thumbnail,
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
                          item.product.name,
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
          _SummaryRow(label: 'Subtotal', value: formatPrice(order.subtotal)),
          if (order.discount > 0)
            _SummaryRow(
              label: 'Discount',
              value: '−${formatPrice(order.discount)}',
            ),
          _SummaryRow(
            label: 'Shipping',
            value: order.shipping == 0 ? 'Free' : formatPrice(order.shipping),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Text('Total', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(formatPrice(order.total), style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 26),
          Text('Delivery', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            order.shippingAddress,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (order.giftWrapped || order.giftMessage.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text('Gift', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              <String>[
                if (order.giftWrapped) 'Gift wrapped',
                if (order.giftMessage.isNotEmpty) '“${order.giftMessage}”',
              ].join('\n'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Payment', style: theme.textTheme.titleMedium),
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
              label: const Text('Cancel this order'),
            ),
            const SizedBox(height: 10),
          ],
          if (order.canReturn) ...<Widget>[
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.returnRequest(order.id)),
              icon: const Icon(Icons.assignment_return_outlined, size: 20),
              label: Text('Return items · ${order.returnDaysLeft} days left'),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.invoice(order.id)),
            icon: const Icon(Icons.receipt_outlined, size: 20),
            label: const Text('View receipt'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: items.isEmpty
                ? null
                : () => _reorder(context, ref, items),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Buy these again'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, Order order) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'It hasn’t shipped yet, so it can still be stopped. This can’t be '
          'undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (!(yes ?? false)) return;

    final bool ok = await ref.read(ordersProvider.notifier).cancel(order.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Order cancelled'
                : 'Too late to cancel — it has already shipped',
          ),
        ),
      );
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    List<CartItem> items,
  ) async {
    for (final CartItem item in items) {
      await ref
          .read(cartProvider.notifier)
          .add(
            item.product,
            size: item.size,
            color: item.color,
            quantity: item.quantity,
          );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Added back to your bag'),
          action: SnackBarAction(
            label: 'View bag',
            onPressed: () => context.go(Routes.cart),
          ),
        ),
      );
  }
}

/// Processing → Shipped → Delivered progress rail.
class _Tracker extends StatelessWidget {
  const _Tracker({required this.status, required this.eta});

  final OrderStatus status;
  final DateTime eta;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int activeIndex = OrderStatus.values.indexOf(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            status == OrderStatus.delivered
                ? 'Delivered'
                : 'Arriving by ${formatDeliveryDate(eta)}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              for (int i = 0; i < OrderStatus.values.length; i++) ...<Widget>[
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
                if (i < OrderStatus.values.length - 1)
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
              for (final OrderStatus s in OrderStatus.values)
                Text(
                  s.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: s.index <= activeIndex
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
                  refunded ? 'Refunded' : 'Return in progress',
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
            refunded
                ? '${request.reason.label} · refunded to ${order.paymentLabel}'
                : '${request.reason.label} · expect your refund by '
                      '${formatDeliveryDate(request.expectedRefundBy)}',
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
                child: const Text('Withdraw return'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
