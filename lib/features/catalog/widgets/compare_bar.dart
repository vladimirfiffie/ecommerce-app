import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../state/compare_provider.dart';
import 'compare_sheet.dart';

/// The strip that appears once something has been picked to compare.
///
/// Nothing until then: a permanent bar advertising a feature nobody has
/// started using is a permanent tax on the screen.
class CompareBar extends ConsumerWidget {
  const CompareBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<Product> picked = ref.watch(compareItemsProvider);
    if (picked.isEmpty) return const SizedBox.shrink();

    final bool enough = picked.length > 1;

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      picked.length == 1
                          ? '1 picked to compare'
                          : '${picked.length} picked to compare',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      enough
                          ? picked.map((Product p) => p.name).join(' · ')
                          : 'Hold another product to add it',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => ref.read(compareProvider.notifier).clear(),
              ),
              FilledButton(
                // One product has nothing to sit beside.
                onPressed: enough ? () => showCompareSheet(context) : null,
                child: const Text('Compare'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
