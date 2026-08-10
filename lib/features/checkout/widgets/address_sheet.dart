import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/address.dart';
import '../../../state/addresses_provider.dart';

/// Opens the add/edit address form.
Future<void> showAddressSheet(BuildContext context, {Address? existing}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AddressSheet(existing: existing),
      ),
    );

class AddressSheet extends ConsumerStatefulWidget {
  const AddressSheet({super.key, this.existing});

  final Address? existing;

  @override
  ConsumerState<AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends ConsumerState<AddressSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _label = TextEditingController(
    text: widget.existing?.label ?? 'Home',
  );
  late final TextEditingController _recipient = TextEditingController(
    text: widget.existing?.recipient ?? '',
  );
  late final TextEditingController _line1 = TextEditingController(
    text: widget.existing?.line1 ?? '',
  );
  late final TextEditingController _city = TextEditingController(
    text: widget.existing?.city ?? '',
  );
  late final TextEditingController _postcode = TextEditingController(
    text: widget.existing?.postcode ?? '',
  );
  late final TextEditingController _country = TextEditingController(
    text: widget.existing?.country ?? 'United States',
  );

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _line1.dispose();
    _city.dispose();
    _postcode.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final Address address = Address(
      id:
          widget.existing?.id ??
          'addr-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
      label: _label.text.trim(),
      recipient: _recipient.text.trim(),
      line1: _line1.text.trim(),
      city: _city.text.trim(),
      postcode: _postcode.text.trim(),
      country: _country.text.trim(),
    );

    await ref.read(addressesProvider.notifier).upsert(address);
    ref.read(selectedAddressIdProvider.notifier).select(address.id);

    if (mounted) Navigator.of(context).pop();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

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
              Text(
                widget.existing == null ? 'New address' : 'Edit address',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _label,
                      validator: _required,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Label'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _recipient,
                      validator: _required,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _line1,
                validator: _required,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Street address'),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _city,
                      validator: _required,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _postcode,
                      validator: _required,
                      decoration: const InputDecoration(labelText: 'ZIP'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _country,
                validator: _required,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: const Text('Save address')),
            ],
          ),
        ),
      ),
    );
  }
}
