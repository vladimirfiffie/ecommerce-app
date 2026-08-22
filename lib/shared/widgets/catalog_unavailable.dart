import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_providers.dart';
import 'empty_state.dart';
import '../../l10n/generated/app_localizations.dart';

/// Shown where stored data can't be drawn because the catalog is missing —
/// not because there's nothing to draw.
///
/// The bag and the wishlist keep product ids and resolve them against the
/// catalog on read, so a failed load makes both look empty. Telling someone
/// their bag is empty when it isn't sends them off to shop for things they
/// already picked; this says what actually happened and offers a way out.
class CatalogUnavailable extends ConsumerWidget {
  const CatalogUnavailable({required this.title, super.key});

  /// What couldn't be shown, e.g. `Couldn’t load your bag`.
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    icon: Icons.cloud_off_rounded,
    title: title,
    message: AppL10n.of(context).catalogUnreachableMessage,
    actionLabel: AppL10n.of(context).retry,
    onAction: () => ref.invalidate(catalogProvider),
  );
}

/// A quiet notice that some stored lines resolved to nothing even though the
/// catalog loaded — the products behind them have been delisted.
class UnavailableLinesNotice extends StatelessWidget {
  const UnavailableLinesNotice({required this.count, super.key, this.onRemove});

  final int count;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppL10n.of(context).itemsNoLongerSold(count),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (onRemove != null)
            TextButton(onPressed: onRemove, child: const Text('Remove')),
        ],
      ),
    );
  }
}
