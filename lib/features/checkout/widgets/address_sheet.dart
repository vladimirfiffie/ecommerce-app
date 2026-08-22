import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';

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

  /// Caps a field at the length the model will accept, so an over-long paste
  /// is stopped at the keyboard rather than at validation.
  List<TextInputFormatter> _limit(int max) => <TextInputFormatter>[
    LengthLimitingTextInputFormatter(max),
  ];

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
                      validator: (String? v) =>
                          AddressValidator.validateLabel(v ?? ''),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      inputFormatters: _limit(24),
                      decoration: InputDecoration(
                        labelText: AppL10n.of(context).addressLabelField,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _recipient,
                      validator: (String? v) =>
                          AddressValidator.validateRecipient(v ?? ''),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.name],
                      inputFormatters: _limit(AddressValidator.maxShortField),
                      decoration: InputDecoration(
                        labelText: AppL10n.of(context).addressFullName,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _line1,
                validator: (String? v) =>
                    AddressValidator.validateLine1(v ?? ''),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.streetAddress,
                autofillHints: const <String>[AutofillHints.fullStreetAddress],
                inputFormatters: _limit(AddressValidator.maxLine),
                decoration: InputDecoration(
                  labelText: AppL10n.of(context).addressStreet,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _city,
                      validator: (String? v) =>
                          AddressValidator.validateCity(v ?? ''),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.addressCity],
                      inputFormatters: _limit(AddressValidator.maxShortField),
                      decoration: InputDecoration(
                        labelText: AppL10n.of(context).addressCity,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _postcode,
                      // Country decides the rule, so the postcode has to be
                      // re-checked whenever the country changes underneath it.
                      validator: (String? v) =>
                          AddressValidator.validatePostcode(
                            v ?? '',
                            country: _country.text,
                          ),
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.postalCode],
                      inputFormatters: _limit(AddressValidator.maxPostcode),
                      // The validator already switches on the country; the
                      // label had not, so a UK address asked for a ZIP and
                      // then rejected it for not being one.
                      decoration: InputDecoration(
                        labelText:
                            AddressValidator.isUnitedStates(_country.text)
                            ? AppL10n.of(context).addressPostcodeUs
                            : AppL10n.of(context).addressPostcodeOther,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _country,
                validator: (String? v) =>
                    AddressValidator.validateCountry(v ?? ''),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.countryName],
                inputFormatters: _limit(AddressValidator.maxShortField),
                onFieldSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: AppL10n.of(context).addressCountry,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: Text(AppL10n.of(context).addressSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
