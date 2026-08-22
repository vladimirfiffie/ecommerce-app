import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/credit_entry.dart';
import '../../state/credit_provider.dart';

/// The balance, a place to redeem a gift card, and where every penny of it
/// came from and went.
class StoreCreditScreen extends ConsumerStatefulWidget {
  const StoreCreditScreen({super.key, this.embedded = false});

  /// Shown inside the settings detail pane, where a back button would have
  /// nothing to pop.
  final bool embedded;

  @override
  ConsumerState<StoreCreditScreen> createState() => _StoreCreditScreenState();
}

class _StoreCreditScreenState extends ConsumerState<StoreCreditScreen> {
  final TextEditingController _code = TextEditingController();
  String? _error;
  bool _redeeming = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    setState(() => _redeeming = true);
    final String? refused = await ref
        .read(creditLedgerProvider.notifier)
        .redeem(_code.text);
    if (!mounted) return;
    setState(() {
      _redeeming = false;
      _error = refused;
    });
    if (refused != null) return;

    final String added = _code.text.trim().toUpperCase();
    _code.clear();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$added added — ${formatPrice(kGiftCards[added] ?? 0)} on your '
            'account',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double balance = ref.watch(storeCreditProvider);
    final List<CreditEntry> history = ref.watch(creditHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift cards & credit'),
        automaticallyImplyLeading: !widget.embedded,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: <Widget>[
          _BalanceCard(balance: balance),
          const SizedBox(height: 24),
          Text('Redeem a gift card', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            inputFormatters: <TextInputFormatter>[UpperCaseTextFormatter()],
            onSubmitted: (_) => _redeem(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: 'Gift card code',
              hintText: 'ASTER-GIFT-25',
              errorText: _error,
              prefixIcon: const Icon(Icons.redeem_rounded),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _redeeming ? null : _redeem,
            child: _redeeming
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Text('Add to my account'),
          ),
          const SizedBox(height: 10),
          Text(
            'This build has no card issuer behind it, so it accepts a short '
            'list of demo codes: ${kGiftCards.keys.join(', ')}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          Text('History', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Nothing yet. Redeemed cards, orders that used credit and '
                'refunds paid back as credit all show up here.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final CreditEntry entry in history) _HistoryRow(entry: entry),
          const SizedBox(height: 20),
          Text(
            'Credit is spent before the card is charged, and only ever on this '
            'device. Cancel an order and its credit comes straight back; '
            'return one and the share of the refund that was paid with credit '
            'comes back the same way.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Forces the code to upper case as it is typed, so the field shows what the
/// ledger will actually store.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => TextEditingValue(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
  );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Text(
                'Store credit',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatPrice(balance),
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            balance > 0
                ? 'Goes towards your next order automatically'
                : 'Redeem a gift card to get started',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.85,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final CreditEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool incoming = entry.amount >= 0;

    final (IconData icon, String title) = switch (entry.kind) {
      CreditKind.redeemed => (Icons.redeem_rounded, 'Gift card redeemed'),
      CreditKind.spent => (Icons.shopping_bag_outlined, 'Spent on an order'),
      CreditKind.refunded => (Icons.undo_rounded, 'Refunded to credit'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  '${entry.reference} · ${formatDate(entry.at)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${incoming ? '+' : '−'}${formatPrice(entry.amount.abs())}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: incoming ? AppTheme.success : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
