import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_kit/haptic_kit.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_line.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/haptics_provider.dart';
import '../../state/orders_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';

/// Pick the items going back, say why, see exactly what comes back.
class ReturnRequestScreen extends ConsumerStatefulWidget {
  const ReturnRequestScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<ReturnRequestScreen> createState() =>
      _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends ConsumerState<ReturnRequestScreen> {
  final Set<String> _selected = <String>{};
  final TextEditingController _note = TextEditingController();
  ReturnReason? _reason;
  bool _submitting = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit(Order order, RefundQuote quote) async {
    if (_selected.isEmpty || _reason == null) return;
    setState(() => _submitting = true);

    final bool ok = await ref
        .read(ordersProvider.notifier)
        .requestReturn(
          orderId: order.id,
          lineIds: _selected,
          reason: _reason!,
          refundAmount: quote.total,
          note: _note.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);
    unawaited(
      ref
          .read(hapticsProvider)
          .notification(
            ok
                ? HapticNotificationStyle.success
                : HapticNotificationStyle.error,
          ),
    );

    if (!ok) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('This order can no longer be returned')),
        );
      return;
    }
    context.pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('Return started · ${formatPrice(quote.total)}')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Order? order = ref.watch(orderByIdProvider(widget.orderId));
    final List<OrderLine> items = ref.watch(orderItemsProvider(widget.orderId));

    if (order == null || items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Return')),
        body: EmptyState(
          icon: Icons.assignment_return_outlined,
          title: 'Nothing to return',
          message: 'We couldn’t find that order.',
          actionLabel: 'All orders',
          onAction: () => context.go(Routes.orders),
        ),
      );
    }

    final Map<String, double> lineTotals = <String, double>{
      for (final OrderLine i in items) i.lineId: i.lineTotal,
    };
    final RefundQuote quote = ref
        .read(ordersProvider.notifier)
        .quoteRefund(
          order: order,
          lineIds: _selected,
          reason: _reason ?? ReturnReason.changedMind,
          lineTotals: lineTotals,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Return items')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          Text(
            'What are you sending back?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${order.returnDaysLeft} days left to return this order.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),

          for (final OrderLine item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ItemChoice(
                item: item,
                selected: _selected.contains(item.lineId),
                onChanged: (bool on) => setState(() {
                  if (on) {
                    _selected.add(item.lineId);
                  } else {
                    _selected.remove(item.lineId);
                  }
                }),
              ),
            ),
          if (items.length > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() {
                  if (_selected.length == items.length) {
                    _selected.clear();
                  } else {
                    _selected
                      ..clear()
                      ..addAll(lineTotals.keys);
                  }
                }),
                child: Text(
                  _selected.length == items.length
                      ? 'Clear selection'
                      : 'Select everything',
                ),
              ),
            ),

          const SizedBox(height: 18),
          Text('Why?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final ReturnReason reason in ReturnReason.values)
                ChoiceChip(
                  label: Text(reason.labelIn(AppL10n.of(context))),
                  selected: _reason == reason,
                  labelStyle: TextStyle(
                    color: _reason == reason
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _reason = reason),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            maxLength: 300,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Anything else? (optional)',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 10),
          _RefundBreakdown(quote: quote, empty: _selected.isEmpty),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _selected.isEmpty || _reason == null || _submitting
                ? null
                : () => _submit(order, quote),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(
                    _selected.isEmpty
                        ? 'Choose items to return'
                        : 'Request ${formatPrice(quote.total)} refund',
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemChoice extends StatelessWidget {
  const _ItemChoice({
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  final OrderLine item;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              Checkbox(
                value: selected,
                onChanged: (bool? v) => onChanged(v ?? false),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: AppImage(
                  url: item.imageUrl,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.displayNameIn(AppL10n.of(context)),
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
      ),
    );
  }
}

class _RefundBreakdown extends StatelessWidget {
  const _RefundBreakdown({required this.quote, required this.empty});

  final RefundQuote quote;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Refund estimate', style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: 10),
          if (empty)
            Text(
              'Pick at least one item to see what comes back.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...<Widget>[
            _Line('Items', formatPrice(quote.items)),
            if (quote.shipping > 0)
              _Line('Original shipping', formatPrice(quote.shipping)),
            _Line('Tax', formatPrice(quote.tax)),
            const Divider(height: 20),
            Row(
              children: <Widget>[
                Text('Back on your card', style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  formatPrice(quote.total),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  quote.returnPostagePaidByShop
                      ? Icons.local_shipping_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quote.returnPostagePaidByShop
                        ? 'We got this wrong, so return postage is on us.'
                        : 'Return postage is deducted from your refund unless '
                              'the item arrived damaged or incorrect.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
