import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/cart_provider.dart';
import '../../../state/credit_provider.dart';

/// Subtotal / discount / shipping / tax / total block, shared by the cart and
/// the checkout review step.
class OrderSummary extends ConsumerWidget {
  const OrderSummary({
    super.key,
    this.title = 'Order summary',
    this.showCredit = false,
  });

  final String title;

  /// Whether to break out store credit and what is left to pay.
  ///
  /// Off in the bag: nothing has been settled there yet, and a total that
  /// already had the balance taken off it would be a price the shopper can't
  /// find on any other screen.
  final bool showCredit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final CartSummary summary = ref.watch(cartSummaryProvider);
    final Promo? promo = ref.watch(appliedPromoProvider);
    final CheckoutTotal checkout = ref.watch(checkoutTotalProvider);
    final bool credited = showCredit && checkout.usesCredit;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 16),
          _Line(label: 'Subtotal', value: formatPrice(summary.subtotal)),
          if (summary.discount > 0)
            _Line(
              label: 'Discount${promo == null ? '' : ' (${promo.code})'}',
              value: '−${formatPrice(summary.discount)}',
              highlight: AppTheme.success,
            ),
          _Line(
            label: 'Shipping',
            value: summary.shipping == 0
                ? 'Free'
                : formatPrice(summary.shipping),
            highlight: summary.shipping == 0 ? AppTheme.success : null,
          ),
          if (summary.giftFee > 0)
            _Line(label: 'Gift wrap', value: formatPrice(summary.giftFee)),
          _Line(label: 'Estimated tax', value: formatPrice(summary.tax)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: <Widget>[
              Text(
                credited ? 'Order total' : 'Total',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                formatPrice(summary.total),
                style: credited
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge,
              ),
            ],
          ),
          if (credited) ...<Widget>[
            _Line(
              label: 'Store credit',
              value: '−${formatPrice(checkout.creditApplied)}',
              highlight: AppTheme.success,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: <Widget>[
                Text('To pay', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  formatPrice(checkout.amountDue),
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.highlight});

  final String label;
  final String value;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
              color: highlight,
            ),
          ),
        ],
      ),
    );
  }
}
