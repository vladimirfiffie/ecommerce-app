import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../state/haptics_provider.dart';
import '../../shared/widgets/haptic_controls.dart';
import '../../state/biometrics_provider.dart';
import 'package:haptic_kit/haptic_kit.dart';
import '../../state/notifications_provider.dart';
import '../profile/payment_methods_screen.dart';
import '../../data/models/delivery_option.dart';
import '../../state/payments_provider.dart';
import '../../data/models/payment_card.dart';
import '../../core/layout/two_pane.dart';

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

    // Confirm identity before charging anything, if the shopper asked for it.
    if (ref.read(requireBiometricsProvider)) {
      final AuthOutcome outcome = await ref
          .read(biometricsProvider)
          .authenticate(reason: 'Confirm your identity to place this order');
      if (!mounted) return;
      if (outcome == AuthOutcome.failed) {
        unawaited(
          ref.read(hapticsProvider).notification(HapticNotificationStyle.error),
        );
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('Payment cancelled — not verified')),
          );
        return;
      }
      if (outcome == AuthOutcome.unavailable) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Biometrics unavailable — continuing without verification',
              ),
            ),
          );
      }
    }

    setState(() => _placing = true);
    unawaited(ref.read(hapticsProvider).chargeUp());
    // A beat of latency so the button's progress state is visible; a real
    // backend call would sit here.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final PaymentCard? card = ref.read(selectedCardProvider);
    final Order order = await ref
        .read(ordersProvider.notifier)
        .placeOrder(
          address: address,
          paymentLabel: card?.label ?? 'Card on file',
          delivery: ref.read(deliveryOptionProvider),
        );
    unawaited(ref.read(hapticsProvider).success());
    unawaited(
      ref
          .read(notificationsProvider)
          .announceOrder(
            orderId: order.id,
            itemCount: order.itemCount,
            total: formatPrice(order.total),
          ),
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
    final PaymentCard? payment = ref.watch(selectedCardProvider);

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

    final bool twoPane = useTwoPane(context);

    final Widget stepBody = ListView(
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
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _StepIndicator(step: _step),
        ),
      ),
      // On a tablet the running total sits alongside the step instead of
      // being something you scroll to at the end.
      body: twoPane
          ? TwoPane(
              listFlex: 3,
              detailFlex: 2,
              list: stepBody,
              detail: DetailPaneSurface(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: <Widget>[
                    _BagPreview(items: items),
                    const SizedBox(height: 20),
                    const OrderSummary(),
                  ],
                ),
              ),
            )
          : stepBody,
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
                  child: _placing
                      ? const FilledButton(
                          onPressed: null,
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        )
                      : _step < 2
                      ? FilledButton(
                          onPressed: () => setState(() => _step += 1),
                          child: const Text('Continue'),
                        )
                      // The last step is the irreversible one, so it asks for
                      // a deliberate gesture rather than a single tap.
                      : NovaSlideToConfirm(
                          label: 'Slide to pay ${formatPrice(summary.total)}',
                          fallbackLabel: 'Pay ${formatPrice(summary.total)}',
                          onConfirmed: _placeOrder,
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
  static const Duration _duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < _labels.length; i++) ...<Widget>[
            _StepDot(index: i, step: step),

            // Only the current step is labelled — three labels plus their
            // connectors don't fit a narrow phone. It cross-fades and slides
            // as the step changes rather than cutting.
            AnimatedSize(
              duration: _duration,
              curve: Curves.easeOutCubic,
              child: i == step
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child:
                          Text(
                                _labels[i],
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                              .animate(key: ValueKey<int>(i))
                              .fadeIn(duration: _duration)
                              .moveX(
                                begin: -6,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),
                    )
                  : const SizedBox.shrink(),
            ),

            if (i < _labels.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _StepConnector(filled: i < step),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// One numbered dot, which fills and swaps its number for a tick as the
/// checkout advances past it.
class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.step});

  final int index;
  final int step;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool reached = index <= step;
    final bool done = index < step;

    return AnimatedScale(
      // The step you're on sits fractionally larger than the rest.
      scale: index == step ? 1.12 : 1,
      duration: _StepIndicator._duration,
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: _StepIndicator._duration,
        curve: Curves.easeOutCubic,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: reached
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: _StepIndicator._duration,
            transitionBuilder: (Widget child, Animation<double> animation) =>
                ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
            child: done
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey<String>('done'),
                    size: 15,
                    color: theme.colorScheme.onPrimary,
                  )
                : Text(
                    '${index + 1}',
                    key: ValueKey<int>(index),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: reached
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The line between two dots. Fills left-to-right as the step completes,
/// rather than switching colour in one frame.
class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: filled ? 1 : 0),
      duration: _StepIndicator._duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double t, Widget? child) => SizedBox(
        height: 2,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: t,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        Text('Delivery', style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        for (final DeliveryOption option in DeliveryOption.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableTile(
              selected: option == ref.watch(deliveryOptionProvider),
              onTap: () =>
                  ref.read(deliveryOptionProvider.notifier).select(option),
              leading: Icon(option.icon),
              title: option.price == 0
                  ? '${option.label}  ·  Free'
                  : '${option.label}  ·  ${formatPrice(option.price)}',
              subtitle: option == DeliveryOption.pickup
                  ? option.blurb
                  : '${option.blurb} · by '
                        '${formatDeliveryDate(option.estimatedArrival(DateTime.now()))}',
            ),
          ),
      ],
    );
  }
}

class _PaymentStep extends ConsumerWidget {
  const _PaymentStep({required this.selected});

  final PaymentCard? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<PaymentCard> cards = ref.watch(paymentCardsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Pay with', style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        if (cards.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('No cards saved', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Add one to continue. Only the last four digits are stored.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => showAddCardSheet(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add a card'),
                ),
              ],
            ),
          )
        else ...<Widget>[
          for (final PaymentCard card in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SelectableTile(
                selected: card.id == selected?.id,
                onTap: card.isExpired
                    ? null
                    : () => ref
                          .read(selectedCardIdProvider.notifier)
                          .select(card.id),
                leading: Icon(card.brand.icon),
                title: card.label,
                subtitle: card.isExpired
                    ? 'Expired ${card.expiryLabel}'
                    : 'Expires ${card.expiryLabel}',
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showAddCardSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add another card'),
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (ref.watch(requireBiometricsProvider))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.fingerprint_rounded,
                  size: 19,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You\u2019ll be asked to verify before this order is placed.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
  final PaymentCard? payment;

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
          value: payment?.label ?? 'No card selected',
        ),
        const SizedBox(height: 24),
        const _GiftSection(),
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
  final VoidCallback? onTap;
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

/// Gift wrapping and a message, on the review step where the shopper is
/// already looking at what they're sending.
class _GiftSection extends ConsumerStatefulWidget {
  const _GiftSection();

  @override
  ConsumerState<_GiftSection> createState() => _GiftSectionState();
}

class _GiftSectionState extends ConsumerState<_GiftSection> {
  late final TextEditingController _message = TextEditingController(
    text: ref.read(giftOptionsProvider).message,
  );

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GiftOptions gift = ref.watch(giftOptionsProvider);
    final GiftOptionsNotifier notifier = ref.read(giftOptionsProvider.notifier);

    // A Material, not a coloured Container: ListTile paints its ink on the
    // nearest Material ancestor, and a DecoratedBox in between hides it,
    // which Flutter asserts on.
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                Icons.card_giftcard_rounded,
                color: theme.colorScheme.primary,
              ),
              title: Text('Gift wrap', style: theme.textTheme.titleSmall),
              subtitle: Text(
                'Wrapped in tissue and ribbon · '
                '${formatPrice(GiftOptions.wrapFee)}',
                style: theme.textTheme.bodySmall,
              ),
              value: gift.wrapped,
              onChanged: notifier.setWrapped,
            ),
            TextField(
              controller: _message,
              minLines: 2,
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              onChanged: notifier.setMessage,
              decoration: const InputDecoration(
                labelText: 'Gift message (optional)',
                hintText: 'Happy birthday!',
                alignLabelWithHint: true,
              ),
            ),
            if (gift.isGift)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Prices are left off the packing slip for gifts.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact list of what's being bought, for the checkout side pane.
class _BagPreview extends StatelessWidget {
  const _BagPreview({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${items.length} ${items.length == 1 ? 'item' : 'items'}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final CartItem item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: AppImage(
                    url: item.product.thumbnail,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '×${item.quantity}',
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
