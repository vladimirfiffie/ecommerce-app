import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/orders_provider.dart';

/// Builds the plain-text receipt that gets shared or copied.
///
/// Kept separate from the widget so the format can be tested without pumping
/// a screen.
String buildInvoiceText(Order order, List<CartItem> items) {
  final StringBuffer out = StringBuffer()
    ..writeln('NOVA — RECEIPT')
    ..writeln('Order ${order.id}')
    ..writeln(formatDate(order.placedAt))
    ..writeln('Status: ${order.status.label}')
    ..writeln()
    ..writeln('ITEMS');

  for (final CartItem item in items) {
    final String variant = item.variantLabel == null
        ? ''
        : ' (${item.variantLabel})';
    out.writeln(
      '${item.quantity} x ${item.product.name}$variant  '
      '${formatPrice(item.lineTotal)}',
    );
  }

  out
    ..writeln()
    ..writeln('Subtotal        ${formatPrice(order.subtotal)}');
  if (order.discount > 0) {
    out.writeln('Discount       -${formatPrice(order.discount)}');
  }
  out
    ..writeln(
      'Shipping        '
      '${order.shipping == 0 ? 'Free' : formatPrice(order.shipping)}',
    )
    ..writeln('TOTAL           ${formatPrice(order.total)}')
    ..writeln()
    ..writeln('Delivery: ${order.delivery.label}')
    ..writeln('Ship to: ${order.shippingAddress}')
    ..writeln('Paid with: ${order.paymentLabel}');

  if (order.giftWrapped || order.giftMessage.isNotEmpty) {
    out.writeln();
    if (order.giftWrapped) out.writeln('Gift wrapped');
    if (order.giftMessage.isNotEmpty) {
      out.writeln('Message: ${order.giftMessage}');
    }
  }

  if (order.returnRequest case final ReturnRequest r) {
    out
      ..writeln()
      ..writeln(
        'RETURN: ${r.reason.label} — refund ${formatPrice(r.refundAmount)}',
      );
  }

  out
    ..writeln()
    ..writeln('Nova is a demo storefront. No payment was taken.');
  return out.toString();
}

class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Order? order = ref.watch(orderByIdProvider(orderId));
    final List<CartItem> items = ref.watch(orderItemsProvider(orderId));

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receipt')),
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Receipt unavailable',
          message: 'We couldn’t find order $orderId.',
          actionLabel: 'All orders',
          onAction: () => context.go(Routes.orders),
        ),
      );
    }

    final String text = buildInvoiceText(order, items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(const SnackBar(content: Text('Receipt copied')));
            },
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: text, subject: 'Nova receipt ${order.id}'),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 6),
                      Text('NOVA', style: theme.textTheme.titleLarge),
                      Text(
                        'Receipt',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 28),
                _Row('Order', order.id),
                _Row('Placed', formatDate(order.placedAt)),
                _Row('Status', order.status.label),
                _Row('Delivery', order.delivery.label),
                const Divider(height: 28),

                for (final CartItem item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${item.quantity}×',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.product.name,
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (item.variantLabel != null)
                                Text(
                                  item.variantLabel!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          formatPrice(item.lineTotal),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 28),
                _Row('Subtotal', formatPrice(order.subtotal)),
                if (order.discount > 0)
                  _Row('Discount', '−${formatPrice(order.discount)}'),
                _Row(
                  'Shipping',
                  order.shipping == 0 ? 'Free' : formatPrice(order.shipping),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text('Total', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      formatPrice(order.total),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const Divider(height: 28),
                _Row('Ship to', order.shippingAddress, wrap: true),
                _Row('Paid with', order.paymentLabel),
                if (order.returnRequest case final ReturnRequest r) ...<Widget>[
                  const Divider(height: 28),
                  _Row('Return', r.reason.label),
                  _Row('Refund', formatPrice(r.refundAmount)),
                ],
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Nova is a demo storefront. No payment was taken.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.wrap = false});

  final String label;
  final String value;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: wrap ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
