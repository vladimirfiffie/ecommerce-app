import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/address.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/addresses_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/orders_provider.dart';
import '../cart/widgets/order_summary.dart';
import 'widgets/address_sheet.dart';

/// Three-step checkout: shipping → payment → review.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _step = 0;
  bool _placing = false;

  Future<void> _placeOrder() async {
    final Address? address = ref.read(selectedAddressProvider);
    if (address == null) {
      setState(() => _step = 0);
      return;
    }

    setState(() => _placing = true);
    unawaited(HapticFeedback.mediumImpact());
    // A beat of latency so the button's progress state is visible; a real
    // backend call would sit here.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final Order order = await ref
        .read(ordersProvider.notifier)
        .placeOrder(
          address: address,
          payment: ref.read(selectedPaymentProvider),
        );

    if (!mounted) return;
    setState(() => _placing = false);
    context.pushReplacement(Routes.confirmation(order.id));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<CartItem> items = ref.watch(cartItemsProvider);
    final CartSummary summary = ref.watch(cartSummaryProvider);
    final Address? address = ref.watch(selectedAddressProvider);
    final PaymentMethod payment = ref.watch(selectedPaymentProvider);

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Nothing to check out',
          message: 'Your bag is empty.',
          actionLabel: 'Browse the shop',
          onAction: () => context.go(Routes.catalog),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _StepIndicator(step: _step),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: <Widget>[
          switch (_step) {
            0 => _ShippingStep(
              address: address,
              onEdit: () => showAddressSheet(context),
            ),
            1 => _PaymentStep(selected: payment),
            _ => _ReviewStep(items: items, address: address, payment: payment),
          },
        ],
      ),
      bottomNavigationBar: Container(
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
                if (_step > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 110,
                      child: OutlinedButton(
                        onPressed: _placing
                            ? null
                            : () => setState(() => _step -= 1),
                        child: const Text('Back'),
                      ),
                    ),
                  ),
                Expanded(
                  child: FilledButton(
                    onPressed: _placing
                        ? null
                        : _step < 2
                        ? () => setState(() => _step += 1)
                        : _placeOrder,
                    child: _placing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(
                            _step < 2
                                ? 'Continue'
                                : 'Pay ${formatPrice(summary.total)}',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  static const List<String> _labels = <String>['Shipping', 'Payment', 'Review'];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < _labels.length; i++) ...<Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= step
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: i < step
                    ? Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: theme.colorScheme.onPrimary,
                      )
                    : Text(
                        '${i + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: i <= step
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            // Only the current step is labelled — three labels plus their
            // connectors don't fit a narrow phone.
            if (i == step) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                _labels[i],
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (i < _labels.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Divider(
                    color: i < step
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ShippingStep extends ConsumerWidget {
  const _ShippingStep({required this.address, required this.onEdit});

  final Address? address;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<Address> all = ref.watch(addressesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Ship to', style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        for (final Address a in all)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableTile(
              selected: a.id == address?.id,
              onTap: () =>
                  ref.read(selectedAddressIdProvider.notifier).select(a.id),
              leading: Icon(
                a.label == 'Work' ? Icons.business_rounded : Icons.home_rounded,
              ),
              title: '${a.label}  ·  ${a.recipient}',
              subtitle: a.oneLine,
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add a new address'),
        ),
        const SizedBox(height: 26),
        Text('Delivery speed', style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        _SelectableTile(
          selected: true,
          onTap: () {},
          leading: const Icon(Icons.local_shipping_outlined),
          title: 'Standard  ·  3–5 business days',
          subtitle:
              'Arrives by ${formatDeliveryDate(DateTime.now().add(const Duration(days: 4)))}',
        ),
      ],
    );
  }
}

class _PaymentStep extends ConsumerWidget {
  const _PaymentStep({required this.selected});

  final PaymentMethod selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Pay with', style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        for (final PaymentMethod method in kPaymentMethods)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableTile(
              selected: method.id == selected.id,
              onTap: () =>
                  ref.read(selectedPaymentProvider.notifier).select(method),
              leading: Icon(
                method.id == 'applepay'
                    ? Icons.account_balance_wallet_rounded
                    : Icons.credit_card_rounded,
              ),
              title: method.label,
              subtitle: method.expiry == '—'
                  ? 'Balance available'
                  : 'Expires ${method.expiry}',
            ),
          ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.45,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.lock_outline_rounded,
                size: 19,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Demo checkout — no card is charged and no payment data is '
                  'collected or stored.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.items,
    required this.address,
    required this.payment,
  });

  final List<CartItem> items;
  final Address? address;
  final PaymentMethod payment;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Review your order', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
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
                        maxLines: 1,
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
        _ReviewRow(
          icon: Icons.location_on_outlined,
          label: 'Shipping to',
          value: address == null
              ? 'No address selected'
              : '${address!.recipient}\n${address!.oneLine}',
        ),
        const SizedBox(height: 14),
        _ReviewRow(
          icon: Icons.credit_card_rounded,
          label: 'Paying with',
          value: payment.label,
        ),
        const SizedBox(height: 24),
        const OrderSummary(title: 'Total'),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              IconTheme.merge(
                data: IconThemeData(
                  size: 22,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                child: leading,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
