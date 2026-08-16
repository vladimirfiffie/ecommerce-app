import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/cart_provider.dart';

/// Promo code entry. Applied codes collapse into a removable row.
class PromoField extends ConsumerStatefulWidget {
  const PromoField({super.key});

  @override
  ConsumerState<PromoField> createState() => _PromoFieldState();
}

class _PromoFieldState extends ConsumerState<PromoField> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final double subtotal = ref.read(cartSummaryProvider).subtotal;
    final String? error = ref
        .read(appliedPromoProvider.notifier)
        .apply(_controller.text, subtotal);
    setState(() => _error = error);
    if (error == null) {
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Promo? applied = ref.watch(appliedPromoProvider);

    if (applied != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.local_offer_rounded,
              size: 18,
              color: AppTheme.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(applied.code, style: theme.textTheme.titleSmall),
                  Text(
                    applied.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove code',
              onPressed: () {
                ref.read(appliedPromoProvider.notifier).clear();
                setState(() => _error = null);
              },
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      );
    }

    final PromoOffer? best = ref.watch(bestPromoProvider);
    final double subtotal = ref.watch(cartSummaryProvider).subtotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // The codes were all listed below with nothing to choose between
        // them. This says which one is worth having and what it comes to.
        if (best != null) ...<Widget>[
          _BestOffer(
            offer: best,
            onApply: () {
              _controller.text = best.promo.code;
              _apply();
            },
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _controller,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _apply(),
                decoration: InputDecoration(
                  hintText: 'Promo code',
                  prefixIcon: const Icon(Icons.local_offer_outlined, size: 20),
                  errorText: _error,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // The themed minimumSize is `Size.fromHeight(54)`, i.e. infinite
            // width — inside a Row that has to be constrained explicitly.
            SizedBox(
              height: 54,
              width: 96,
              child: OutlinedButton(
                onPressed: _apply,
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (final Promo promo in kPromos)
              if (subtotal >= promo.minSubtotal)
                ActionChip(
                  label: Text(promo.code),
                  avatar: const Icon(Icons.bolt_rounded, size: 15),
                  onPressed: () {
                    _controller.text = promo.code;
                    _apply();
                  },
                )
              else
                // Offering a code the bag can't use yet, and rejecting it on
                // tap, is a worse introduction than saying what it needs.
                Tooltip(
                  message:
                      'Spend ${formatPrice(promo.minSubtotal)} to use this',
                  child: Chip(
                    label: Text(promo.code),
                    avatar: const Icon(Icons.lock_outline_rounded, size: 15),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

/// The code worth having on this bag, and what it takes off.
class _BestOffer extends StatelessWidget {
  const _BestOffer({required this.offer, required this.onApply});

  final PromoOffer offer;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.savings_outlined,
            size: 18,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Best code: ${offer.promo.code}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Saves ${formatPrice(offer.saving)} on this bag',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onApply, child: const Text('Apply')),
        ],
      ),
    );
  }
}
