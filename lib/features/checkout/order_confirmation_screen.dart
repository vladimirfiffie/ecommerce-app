import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/orders_provider.dart';
import '../../state/haptics_provider.dart';
import 'dart:async';

/// Success screen shown straight after an order is placed.
class OrderConfirmationScreen extends ConsumerStatefulWidget {
  const OrderConfirmationScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // Celebrate once the screen is actually up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(hapticsProvider).doubleTap());
    });
  }

  @override
  Widget build(BuildContext context) {
    final String orderId = widget.orderId;
    final ThemeData theme = Theme.of(context);
    final Order? order = ref.watch(orderByIdProvider(orderId));

    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Order not found',
          message: 'We couldn’t find order $orderId.',
          actionLabel: 'Back to shop',
          onAction: () => context.go(Routes.home),
        ),
      );
    }

    return PopScope(
      // Back from here should land on the shop, not the dead checkout route.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              children: <Widget>[
                const Spacer(),
                Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.success.withValues(alpha: 0.14),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 58,
                        color: AppTheme.success,
                      ),
                    )
                    .animate()
                    .scale(
                      duration: 460.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.5, 0.5),
                    )
                    .fadeIn(),
                const SizedBox(height: 28),
                Text(
                  'Order confirmed',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ).animate(delay: 160.ms).fadeIn().moveY(begin: 12, end: 0),
                const SizedBox(height: 10),
                Text(
                  'Thanks! We’re getting order ${order.id} ready to ship.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ).animate(delay: 240.ms).fadeIn(),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(
                    children: <Widget>[
                      _Row(
                        label: 'Items',
                        value:
                            '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
                      ),
                      _Row(
                        label: 'Total paid',
                        value: formatPrice(order.total),
                      ),
                      _Row(
                        label: 'Arrives by',
                        value: formatDeliveryDate(order.estimatedDelivery),
                      ),
                      _Row(label: 'Paid with', value: order.paymentLabel),
                    ],
                  ),
                ).animate(delay: 320.ms).fadeIn().moveY(begin: 16, end: 0),
                const Spacer(),
                FilledButton(
                  onPressed: () =>
                      context.pushReplacement(Routes.order(order.id)),
                  child: const Text('Track this order'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => context.go(Routes.home),
                  child: const Text('Keep shopping'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
