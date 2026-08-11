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
import '../../shared/widgets/animated_check.dart';
import '../../shared/widgets/app_image.dart';
import '../../data/models/cart_item.dart';

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
    final List<CartItem> items = ref.watch(orderItemsProvider(orderId));

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
          child: Center(
            child: ConstrainedBox(
              // Centred and width-limited rather than stretched: a
              // confirmation is a short message, not a page of content.
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  children: <Widget>[
                    const Spacer(),
                    // Draws itself: ring sweeps closed, tick strokes in,
                    // halo expands. Plays once — see AnimatedCheck.
                    const AnimatedCheck(color: AppTheme.success),
                    const SizedBox(height: 28),
                    Text(
                      'Order confirmed',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ).animate(delay: 460.ms).fadeIn().moveY(begin: 12, end: 0),
                    const SizedBox(height: 10),
                    Text(
                      'Thanks! We’re getting order ${order.id} ready to ship.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ).animate(delay: 560.ms).fadeIn(),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Column(
                        children: <Widget>[
                          if (items.isNotEmpty) ...<Widget>[
                            _OrderedItems(items: items),
                            const SizedBox(height: 14),
                            Divider(
                              height: 1,
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 8),
                          ],
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
                    ).animate(delay: 660.ms).fadeIn().moveY(begin: 16, end: 0),
                    const Spacer(),
                    FilledButton(
                      onPressed: () =>
                          context.pushReplacement(Routes.order(order.id)),
                      child: const Text('Track this order'),
                    ).animate(delay: 780.ms).fadeIn().moveY(begin: 10, end: 0),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context.go(Routes.home),
                      child: const Text('Keep shopping'),
                    ).animate(delay: 860.ms).fadeIn().moveY(begin: 10, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thumbnails of what was just bought — a confirmation that names a total
/// but shows nothing makes you go and check the order to be sure.
class _OrderedItems extends StatelessWidget {
  const _OrderedItems({required this.items});

  final List<CartItem> items;

  /// Beyond this the strip stops being scannable, so the rest is a count.
  static const int _maxShown = 4;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<CartItem> shown = items.take(_maxShown).toList();
    final int overflow = items.length - shown.length;

    return Row(
      children: <Widget>[
        for (int i = 0; i < shown.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _Thumb(item: shown[i])
                .animate(delay: (700 + i * 70).ms)
                .fadeIn(duration: 260.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1, 1),
                ),
          ),
        if (overflow > 0)
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              '+$overflow',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const Spacer(),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: AppImage(
              url: item.product.thumbnail,
              fit: BoxFit.contain,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          if (item.quantity > 1)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.quantity}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
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
