import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/profile_provider.dart';

/// Opens the "what should we call you" sheet.
Future<void> showEditNameSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const EditNameSheet(),
      ),
    );

class EditNameSheet extends ConsumerStatefulWidget {
  const EditNameSheet({super.key});

  @override
  ConsumerState<EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends ConsumerState<EditNameSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(displayNameProvider),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(displayNameProvider.notifier).set(_controller.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('What should we call you?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Used for the greeting on Home. Leaving it blank restores the '
              'default.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            AdaptiveTextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.name,
              autofillHints: const <String>[AutofillHints.name],
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              maxLength: 32,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Name',
                counterText: '',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
