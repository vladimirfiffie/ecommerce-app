import '../../shared/widgets/adaptive_screen.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/address.dart';
import '../../shared/widgets/empty_state.dart';
import '../../state/addresses_provider.dart';
import '../checkout/widgets/address_sheet.dart';
import '../../shared/widgets/confirm.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key, this.embedded = false});

  /// Shown inside the settings detail pane, where a back button
  /// would have nothing to pop.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<Address> addresses = ref.watch(addressesProvider);
    final Address? selected = ref.watch(selectedAddressProvider);

    return AdaptiveScreen(
      title: 'Addresses',
      automaticallyImplyLeading: !embedded,
      floatingActionButton: addresses.isEmpty
          ? null
          // Extended FABs are a Material idea; iOS gets a round button, so
          // the label rides inside it rather than beside it.
          : AdaptiveFloatingActionButton(
              onPressed: () => showAddressSheet(context),
              tooltip: 'Add address',
              child: const Icon(Icons.add_rounded),
            ),
      body: addresses.isEmpty
          ? EmptyState(
              icon: Icons.location_off_outlined,
              title: 'No addresses yet',
              message: 'Add one and checkout will use it by default.',
              actionLabel: 'Add an address',
              onAction: () => showAddressSheet(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: <Widget>[
                for (final Address address in addresses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AddressTile(
                      address: address,
                      isDefault: address.id == selected?.id,
                      onSelect: () => ref
                          .read(selectedAddressIdProvider.notifier)
                          .select(address.id),
                      onEdit: () =>
                          showAddressSheet(context, existing: address),
                      onDelete: addresses.length <= 1
                          ? null
                          : () => _confirmDelete(context, ref, address),
                    ),
                  ),
                if (addresses.length == 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Your last address can’t be removed — checkout needs '
                      'somewhere to ship to.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Address address,
  ) async {
    final bool yes = await confirmDestructive(
      context,
      title: 'Remove address?',
      message: address.oneLine,
      confirmLabel: 'Remove',
    );
    if (yes) {
      await ref.read(addressesProvider.notifier).remove(address.id);
    }
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.isDefault,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final Address address;
  final bool isDefault;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: isDefault
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDefault
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isDefault ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                address.label.toLowerCase() == 'work'
                    ? Icons.business_rounded
                    : Icons.home_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            '${address.label} · ${address.recipient}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (isDefault) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Default',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address.oneLine,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: <Widget>[
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined, size: 19),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
