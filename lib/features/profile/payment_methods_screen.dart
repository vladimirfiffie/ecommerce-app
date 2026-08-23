import '../../shared/widgets/adaptive_screen.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../../shared/widgets/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/payment_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/payments_provider.dart';
import '../../shared/widgets/confirm.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key, this.embedded = false});

  /// Shown inside the settings detail pane, where a back button
  /// would have nothing to pop.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<PaymentCard> cards = ref.watch(paymentCardsProvider);
    final PaymentCard? selected = ref.watch(selectedCardProvider);

    return AdaptiveScreen(
      title: 'Payment methods',
      automaticallyImplyLeading: !embedded,
      floatingActionButton: cards.isEmpty
          ? null
          // Extended FABs are a Material idea; iOS gets a round button, so
          // the label rides inside it rather than beside it.
          : AdaptiveFloatingActionButton(
              onPressed: () => showAddCardSheet(context),
              tooltip: 'Add card',
              child: const Icon(Icons.add_rounded),
            ),
      body: cards.isEmpty
          ? EmptyState(
              icon: Icons.credit_card_off_outlined,
              title: 'No cards saved',
              message:
                  'Add a card to speed up checkout. Only the last four digits '
                  'are ever stored on this device.',
              actionLabel: 'Add a card',
              onAction: () => showAddCardSheet(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: <Widget>[
                for (final PaymentCard card in cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CardTile(
                      card: card,
                      selected: card.id == selected?.id,
                      onSelect: () => ref
                          .read(selectedCardIdProvider.notifier)
                          .select(card.id),
                      onDelete: () => _confirmDelete(context, ref, card),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Aster stores the brand, expiry, cardholder name and last four '
                  'digits only. The full number is never written to disk and '
                  'the security code is never stored at all. No real payment '
                  'is taken by this build.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PaymentCard card,
  ) async {
    final bool yes = await confirmDestructive(
      context,
      title: 'Remove card?',
      message: '${card.label} will be removed from this device.',
      confirmLabel: 'Remove',
    );
    if (yes) {
      await ref.read(paymentCardsProvider.notifier).remove(card.id);
    }
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  final PaymentCard card;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool expired = card.isExpired;

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: expired ? null : onSelect,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: expired
                  ? theme.colorScheme.error.withValues(alpha: 0.5)
                  : selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                card.brand.icon,
                size: 26,
                color: expired
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(card.label, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      expired
                          ? 'Expired ${card.expiryLabel}'
                          : '${card.holder} · Expires ${card.expiryLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: expired
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected && !expired)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the add-card form.
Future<void> showAddCardSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const AddCardSheet(),
      ),
    );

class AddCardSheet extends ConsumerStatefulWidget {
  const AddCardSheet({super.key});

  @override
  ConsumerState<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends ConsumerState<AddCardSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _expiry = TextEditingController();
  final TextEditingController _cvv = TextEditingController();
  final TextEditingController _holder = TextEditingController();

  CardBrand _brand = CardBrand.unknown;

  @override
  void initState() {
    super.initState();
    _number.addListener(_onNumberChanged);
  }

  @override
  void dispose() {
    _number
      ..removeListener(_onNumberChanged)
      ..dispose();
    _expiry.dispose();
    _cvv.dispose();
    _holder.dispose();
    super.dispose();
  }

  /// Reformats as the shopper types and keeps the brand badge current.
  void _onNumberChanged() {
    final String formatted = CardValidator.format(_number.text);
    if (formatted != _number.text) {
      _number.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    final CardBrand next = CardValidator.brandOf(_number.text);
    if (next != _brand) setState(() => _brand = next);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Only the derived card is persisted — the number and CVV live no longer
    // than these controllers.
    final PaymentCard card = CardValidator.toCard(
      number: _number.text,
      expiry: _expiry.text,
      holder: _holder.text,
    );
    await ref.read(paymentCardsProvider.notifier).save(card);
    if (!mounted) return;
    Navigator.of(context).pop();
    showMessage(context, '${card.label} added');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Add a card',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Icon(_brand.icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    _brand == CardBrand.unknown ? '' : _brand.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AdaptiveTextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                autofillHints: const <String>[AutofillHints.creditCardNumber],
                decoration: const InputDecoration(
                  labelText: 'Card number',
                  hintText: '4242 4242 4242 4242',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
                validator: (String? v) => CardValidator.validateNumber(v ?? ''),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AdaptiveTextFormField(
                      controller: _expiry,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Expiry',
                        hintText: 'MM/YY',
                      ),
                      validator: (String? v) =>
                          CardValidator.validateExpiry(v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdaptiveTextFormField(
                      controller: _cvv,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '•' * _brand.cvvLength,
                      ),
                      validator: (String? v) =>
                          CardValidator.validateCvv(v ?? '', _brand),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AdaptiveTextFormField(
                controller: _holder,
                keyboardType: TextInputType.name,
                // The last field in the form, so the key says so.
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                autofillHints: const <String>[AutofillHints.creditCardName],
                decoration: const InputDecoration(
                  labelText: 'Name on card',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (String? v) => CardValidator.validateHolder(v ?? ''),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Only the last four digits are saved. The CVV is never '
                        'stored. This is a demo — please use a test number '
                        'like 4242 4242 4242 4242 rather than a real card.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Save card')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inserts the `/` in `MM/YY` as the shopper types.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = CardValidator.digitsOnly(newValue.text);
    final String text = digits.length >= 3
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
