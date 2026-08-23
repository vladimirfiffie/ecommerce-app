import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../state/haptics_provider.dart';

/// Haptic preferences: the master switch, how hard it buzzes, and which parts
/// of the app get feedback.
class HapticsSettingsScreen extends ConsumerWidget {
  const HapticsSettingsScreen({super.key, this.embedded = false});

  /// Shown inside the settings detail pane, where a back button
  /// would have nothing to pop.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final HapticSettings settings = ref.watch(hapticSettingsProvider);
    final HapticSettingsNotifier notifier = ref.read(
      hapticSettingsProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haptics'),
        automaticallyImplyLeading: !embedded,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          if (!HapticService.platformSupported) const _UnsupportedBanner(),

          _Card(
            children: <Widget>[
              // The same switch as the channel rows below. This one used to
              // be a hand-built row around a different toggle, which made the
              // master control look like it belonged to another screen.
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Haptic feedback',
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  'Physical feedback as you shop',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: settings.enabled,
                onChanged: (bool v) async {
                  await notifier.setEnabled(v);
                  if (v) await ref.read(hapticsProvider).impact();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionLabel('Strength'),
          const SizedBox(height: 10),
          AdaptiveSegmentedControl(
            labels: <String>[
              for (final HapticIntensity i in HapticIntensity.values) i.label,
            ],
            selectedIndex: HapticIntensity.values.indexOf(settings.intensity),
            enabled: settings.enabled,
            onValueChanged: (int index) async {
              await notifier.setIntensity(HapticIntensity.values[index]);
              // Feel the strength you just picked, at that strength.
              await ref.read(hapticsProvider).impact();
            },
          ),
          const SizedBox(height: 6),
          Text(
            settings.intensity.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),

          // Each switch buzzes as you turn it on, which is the only preview
          // anyone actually needs.
          _SectionLabel('What gets feedback'),
          const SizedBox(height: 6),
          for (final HapticChannel channel in HapticChannel.values)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(channel.label),
              subtitle: Text(channel.description),
              value: settings.channels.contains(channel),
              onChanged: settings.enabled
                  ? (bool v) async {
                      await notifier.setChannel(channel, v);
                      if (v) await ref.read(hapticsProvider).selection();
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}

class _UnsupportedBanner extends StatelessWidget {
  const _UnsupportedBanner();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Haptics need Android or iOS. On this platform the controls '
              'still save, but nothing will buzz.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
    ),
    child: Column(children: children),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.2,
    ),
  );
}
