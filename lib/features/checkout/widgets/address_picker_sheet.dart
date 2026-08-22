import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/address.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../state/addresses_provider.dart';
import 'address_sheet.dart';

/// Picks which saved address something goes to.
///
/// Returns the chosen address, or null when the sheet is dismissed without a
/// choice. That distinction is the whole point: the caller has to be able to
/// tell "they picked the one it was already going to" from "they backed out",
/// and a picker that only sets a provider can't say which happened.
Future<Address?> showAddressPickerSheet(
  BuildContext context, {
  String? currentId,
}) => showModalBottomSheet<Address>(
  context: context,
  isScrollControlled: true,
  builder: (BuildContext context) => AddressPickerSheet(currentId: currentId),
);

class AddressPickerSheet extends ConsumerWidget {
  const AddressPickerSheet({super.key, this.currentId});

  /// The address in force right now, badged so the shopper can see what
  /// they are changing away from.
  final String? currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppL10n l10n = AppL10n.of(context);
    final List<Address> addresses = ref.watch(addressesProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.addressPickerTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            // No empty state: the store seeds one address and refuses to
            // remove the last, so this list is never empty. Copy for a
            // screen that can't happen is copy nobody maintains.
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (final Address address in addresses)
                    _AddressTile(
                      address: address,
                      current: address.id == currentId,
                      onTap: () => Navigator.of(context).pop(address),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: TextButton.icon(
                onPressed: () async {
                  // The form is the one that already exists. Whatever it
                  // saves lands in the list behind this sheet, so there is
                  // nothing to hand back — the shopper picks it here.
                  await showAddressSheet(context);
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(l10n.checkoutAddAddress),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.current,
    required this.onTap,
  });

  final Address address;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Icon(
        address.label == 'Work' ? Icons.business_rounded : Icons.home_rounded,
        color: current
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text('${address.label}  ·  ${address.recipient}'),
      subtitle: Text(
        address.oneLine,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: current
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                AppL10n.of(context).addressPickerCurrent,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            )
          : null,
    );
  }
}
