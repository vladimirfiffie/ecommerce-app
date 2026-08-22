import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/orders_provider.dart';
import '../../state/addresses_provider.dart';
import '../../state/haptics_provider.dart';
import 'package:haptic_kit/haptic_kit.dart';
import '../../shared/widgets/confirm.dart';
import '../../data/models/address.dart';
import 'widgets/address_sheet.dart';
import '../../shared/widgets/animated_check.dart';
import '../../shared/widgets/app_image.dart';
import '../../data/models/order_line.dart';

/// Success screen shown straight after an order is placed.
/// How often the change-window clock redraws.
///
/// Null stops it entirely: a repeating timer schedules a frame per tick, and
/// a test that pumps to settle would never finish. Seconds here because the
/// label counts them.
@visibleForTesting
Duration? changeWindowTick = const Duration(seconds: 1);

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
    final List<OrderLine> items = ref.watch(orderItemsProvider(orderId));

    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: AppL10n.of(context).confirmationNotFoundTitle,
          message: AppL10n.of(context).confirmationNotFoundMessage(orderId),
          actionLabel: AppL10n.of(context).confirmationBackToShop,
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
              // Centered and width-limited rather than stretched: a
              // confirmation is a short message, not a page of content.
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                // The Spacers below centre this on a tall screen; the scroll
                // view keeps it reachable on a short one. Without it the
                // change-window card tips the page into an overflow on a
                // small phone, which is exactly where it matters most.
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) =>
                      SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              children: <Widget>[
                                const Spacer(),
                                // Draws itself: ring sweeps closed, tick strokes in,
                                // halo expands. Plays once — see AnimatedCheck.
                                const AnimatedCheck(color: AppTheme.success),
                                const SizedBox(height: 28),
                                Text(
                                      AppL10n.of(context).confirmationTitle,
                                      style: theme.textTheme.headlineMedium,
                                      textAlign: TextAlign.center,
                                    )
                                    .animate(delay: 460.ms)
                                    .fadeIn()
                                    .moveY(begin: 12, end: 0),
                                const SizedBox(height: 10),
                                Text(
                                  AppL10n.of(
                                    context,
                                  ).confirmationThanks(order.id),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ).animate(delay: 560.ms).fadeIn(),
                                const SizedBox(height: 32),
                                Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMd,
                                        ),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          if (items.isNotEmpty) ...<Widget>[
                                            _OrderedItems(items: items),
                                            const SizedBox(height: 14),
                                            Divider(
                                              height: 1,
                                              color: theme
                                                  .colorScheme
                                                  .outlineVariant
                                                  .withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          _Row(
                                            label: AppL10n.of(
                                              context,
                                            ).confirmationItems,
                                            value: AppL10n.of(
                                              context,
                                            ).orderItemCount(order.itemCount),
                                          ),
                                          _Row(
                                            label: AppL10n.of(
                                              context,
                                            ).confirmationTotalPaid,
                                            value: formatPrice(order.total),
                                          ),
                                          if (order.creditApplied > 0)
                                            _Row(
                                              label: AppL10n.of(
                                                context,
                                              ).summaryStoreCredit,
                                              value:
                                                  '−${formatPrice(order.creditApplied)}',
                                            ),
                                          _Row(
                                            label: AppL10n.of(
                                              context,
                                            ).confirmationArrivesBy,
                                            value: formatDeliveryDate(
                                              order.estimatedDelivery,
                                            ),
                                          ),
                                          _Row(
                                            label: AppL10n.of(
                                              context,
                                            ).confirmationPaidWith,
                                            value: order.paymentLabel,
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate(delay: 660.ms)
                                    .fadeIn()
                                    .moveY(begin: 16, end: 0),
                                const SizedBox(height: 16),
                                _ChangeWindow(order: order),
                                const Spacer(),
                                FilledButton(
                                      onPressed: () => context.pushReplacement(
                                        Routes.order(order.id),
                                      ),
                                      child: Text(
                                        AppL10n.of(context).confirmationTrack,
                                      ),
                                    )
                                    .animate(delay: 780.ms)
                                    .fadeIn()
                                    .moveY(begin: 10, end: 0),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                      onPressed: () => context.go(Routes.home),
                                      child: Text(
                                        AppL10n.of(
                                          context,
                                        ).confirmationKeepShopping,
                                      ),
                                    )
                                    .animate(delay: 860.ms)
                                    .fadeIn()
                                    .moveY(begin: 10, end: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  final List<OrderLine> items;

  /// Beyond this the strip stops being scannable, so the rest is a count.
  static const int _maxShown = 4;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<OrderLine> shown = items.take(_maxShown).toList();
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

  final OrderLine item;

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
              url: item.imageUrl,
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

/// The few minutes after placing an order in which it can still be undone.
///
/// Every shop has this window and most of them hide it: the order is not
/// going anywhere for a while, and a mistake noticed ten seconds later
/// should not need a support conversation. It disappears when the time is
/// up rather than staying on as a dead control.
class _ChangeWindow extends ConsumerStatefulWidget {
  const _ChangeWindow({required this.order});

  final Order order;

  @override
  ConsumerState<_ChangeWindow> createState() => _ChangeWindowState();
}

class _ChangeWindowState extends ConsumerState<_ChangeWindow> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  /// Each fires once. A countdown that buzzed every second would be a
  /// nuisance rather than a warning.
  bool _warnedOneMinute = false;
  bool _warnedClosed = false;

  /// Buzzes at the two moments that matter: the last minute starting, and
  /// the window closing under you. Both go through the service, so the
  /// shopper's intensity and channel settings decide what they feel.
  void _announce(Duration left) {
    final HapticService haptics = ref.read(hapticsProvider);
    if (left == Duration.zero) {
      if (_warnedClosed) return;
      _warnedClosed = true;
      unawaited(haptics.notification(HapticNotificationStyle.warning));
      return;
    }
    if (left.inSeconds <= 60 && !_warnedOneMinute) {
      _warnedOneMinute = true;
      unawaited(haptics.selection());
    }
  }

  @override
  void initState() {
    super.initState();
    final Duration? tick = changeWindowTick;
    if (tick != null) {
      _timer = Timer.periodic(tick, (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    unawaited(ref.read(hapticsProvider).impact());
    final bool yes = await confirmDestructive(
      context,
      title: AppL10n.of(context).confirmationCancelTitle,
      message: AppL10n.of(context).confirmationCancelMessage,
      confirmLabel: AppL10n.of(context).confirmationCancelConfirm,
    );
    if (!yes || !mounted) return;

    final bool done = await ref
        .read(ordersProvider.notifier)
        .cancel(widget.order.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            done
                ? AppL10n.of(context).confirmationCancelled
                : AppL10n.of(context).confirmationTooLateToCancel,
          ),
        ),
      );
    if (done) context.go(Routes.home);
  }

  Future<void> _changeAddress() async {
    unawaited(ref.read(hapticsProvider).impact());
    await showAddressSheet(context);
    if (!mounted) return;

    final Address? picked = ref.read(selectedAddressProvider);
    if (picked == null) return;

    final bool done = await ref
        .read(ordersProvider.notifier)
        .changeAddress(widget.order.id, picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            done
                // .label, not the Address itself: interpolating the object
                // printed "Instance of 'Address'" into the snackbar.
                ? AppL10n.of(context).confirmationAddressChanged(picked.label)
                : AppL10n.of(context).confirmationTooLateToChange,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Read from the store rather than the argument: cancelling has to take
    // this card off the screen it is drawn on.
    final Order order =
        ref.watch(orderByIdProvider(widget.order.id)) ?? widget.order;
    final Duration left = order.changeWindowLeft;
    _announce(left);
    if (left == Duration.zero) return const SizedBox.shrink();

    final String clock =
        '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      key: ValueKey<String>('change-window-${_now.minute}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                Icons.timer_outlined,
                size: 18,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppL10n.of(context).changeWindowLeft(clock),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              AppL10n.of(context).changeWindowBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          // Shared width rather than a Spacer between them: two full-width
          // labels and a gap do not fit across a small phone.
          Row(
            children: <Widget>[
              Expanded(
                child: TextButton(
                  onPressed: _changeAddress,
                  child: Text(AppL10n.of(context).confirmationChangeAddress),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _cancel,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: Text(AppL10n.of(context).confirmationCancelConfirm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
