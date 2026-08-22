import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../state/fit_provider.dart';

/// Three questions and a suggested size.
///
/// The catalog's size runs are a shop convention rather than per-product
/// measurements, so a shopper has nothing to go on but the chart. This turns
/// the chart into an answer, and says plainly that it is a starting point.
///
/// Returns the size chosen, or null if the sheet was dismissed.
Future<String?> showSizeCalculatorSheet(
  BuildContext context,
  List<String> sizes,
) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (BuildContext context) => _SizeCalculatorSheet(sizes: sizes),
);

class _SizeCalculatorSheet extends ConsumerStatefulWidget {
  const _SizeCalculatorSheet({required this.sizes});

  final List<String> sizes;

  @override
  ConsumerState<_SizeCalculatorSheet> createState() =>
      _SizeCalculatorSheetState();
}

class _SizeCalculatorSheetState extends ConsumerState<_SizeCalculatorSheet> {
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late FitPreference _preference;

  @override
  void initState() {
    super.initState();
    // Answered before? Then this is a confirmation, not an interrogation.
    final FitProfile saved = ref.read(fitProfileProvider);
    _height = TextEditingController(text: saved.heightCm?.toString() ?? '');
    _weight = TextEditingController(text: saved.weightKg?.toString() ?? '');
    _preference = saved.preference;
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  FitProfile get _answers => FitProfile(
    heightCm: int.tryParse(_height.text.trim()),
    weightKg: int.tryParse(_weight.text.trim()),
    preference: _preference,
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final FitProfile answers = _answers;
    final String? suggestion = recommendedSize(answers, widget.sizes);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Find my size', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Three questions, kept on this device and reused next time.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      suffixText: 'cm',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      suffixText: 'kg',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'How do you like it to fit?',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final FitPreference option in FitPreference.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: _preference == option,
                    onSelected: (_) => setState(() => _preference = option),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _preference.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (suggestion != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Try size $suggestion',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A starting point from height, weight and how you like '
                      'things to sit — not a measurement of you or of this '
                      'particular garment.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'Fill both in and a size will show up here.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: suggestion == null
                  ? null
                  : () async {
                      await ref.read(fitProfileProvider.notifier).save(answers);
                      if (context.mounted) {
                        Navigator.of(context).pop(suggestion);
                      }
                    },
              child: Text(
                suggestion == null ? 'Use this size' : 'Use size $suggestion',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
