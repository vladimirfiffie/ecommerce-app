import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_kit/haptic_kit.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/haptic_controls.dart';
import '../../state/haptics_provider.dart';

/// Everything haptic in one place: the shopper's preferences up top, a live
/// capability report, and a playground that exercises every primitive and
/// widget `haptic_kit` exposes.
class HapticsSettingsScreen extends ConsumerStatefulWidget {
  const HapticsSettingsScreen({super.key, this.embedded = false});

  /// Shown inside the settings detail pane, where a back button
  /// would have nothing to pop.
  final bool embedded;

  @override
  ConsumerState<HapticsSettingsScreen> createState() =>
      _HapticsSettingsScreenState();
}

class _HapticsSettingsScreenState extends ConsumerState<HapticsSettingsScreen> {
  final GlobalKey<HapticShakeState> _shakeKey = GlobalKey<HapticShakeState>();
  final GlobalKey<HapticPulseState> _pulseKey = GlobalKey<HapticPulseState>();

  double _amplitude = 180;
  double _demoSlider = 40;
  int _demoStepper = 2;
  int _demoRating = 4;
  bool _demoToggle = true;

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  /// Runs a playground action and reports anything the plugin rejects, rather
  /// than failing silently the way the rest of the app deliberately does.
  Future<void> _run(String label, Future<void> Function() action) async {
    try {
      await action();
      if (mounted && !HapticService.platformSupported) {
        _toast('$label — no haptics on this platform');
      }
    } on VibrationException catch (error) {
      if (mounted) _toast('$label failed: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HapticSettings settings = ref.watch(hapticSettingsProvider);
    final HapticSettingsNotifier notifier = ref.read(
      hapticSettingsProvider.notifier,
    );
    final HapticService haptics = ref.watch(hapticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haptics'),
        automaticallyImplyLeading: !widget.embedded,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          if (!HapticService.platformSupported) const _UnsupportedBanner(),

          _Card(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Haptic feedback',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Physical feedback as you shop',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NovaToggle(
                    value: settings.enabled,
                    onChanged: (bool v) async {
                      await notifier.setEnabled(v);
                      if (v) await ref.read(hapticsProvider).impact();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionLabel('Strength'),
          const SizedBox(height: 10),
          SegmentedButton<HapticIntensity>(
            segments: <ButtonSegment<HapticIntensity>>[
              for (final HapticIntensity i in HapticIntensity.values)
                ButtonSegment<HapticIntensity>(value: i, label: Text(i.label)),
            ],
            selected: <HapticIntensity>{settings.intensity},
            onSelectionChanged: settings.enabled
                ? (Set<HapticIntensity> s) async {
                    await notifier.setIntensity(s.first);
                    await ref.read(hapticsProvider).impact();
                  }
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            settings.intensity.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),

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
          const SizedBox(height: 22),

          _SectionLabel('This device'),
          const SizedBox(height: 10),
          const _CapabilitiesCard(),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final bool ready = await ref.read(hapticsProvider).prepare();
              if (!context.mounted) return;
              _toast(
                ready
                    ? 'Generators pre-warmed (iOS)'
                    : 'Nothing to pre-warm on this platform',
              );
            },
            icon: const Icon(Icons.bolt_rounded, size: 20),
            label: const Text('Prepare generators'),
          ),
          const SizedBox(height: 30),

          Text('Playground', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Try every kind of feedback. These fire regardless of the '
            'channel switches above so you can compare them.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),

          _SectionLabel('Impact'),
          const SizedBox(height: 10),
          _ChipRow(
            children: <Widget>[
              for (final HapticImpactStyle style in HapticImpactStyle.values)
                ActionChip(
                  label: Text(style.name),
                  onPressed: () => _run(
                    style.name,
                    () => Haptics.impact(haptics.scale(style)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),

          _SectionLabel('Notification'),
          const SizedBox(height: 10),
          _ChipRow(
            children: <Widget>[
              for (final HapticNotificationStyle style
                  in HapticNotificationStyle.values)
                ActionChip(
                  avatar: Icon(switch (style) {
                    HapticNotificationStyle.success =>
                      Icons.check_circle_outline_rounded,
                    HapticNotificationStyle.warning =>
                      Icons.warning_amber_rounded,
                    HapticNotificationStyle.error =>
                      Icons.error_outline_rounded,
                  }, size: 16),
                  label: Text(style.name),
                  onPressed: () =>
                      _run(style.name, () => Haptics.notification(style)),
                ),
              ActionChip(
                avatar: const Icon(Icons.touch_app_outlined, size: 16),
                label: const Text('selection'),
                onPressed: () => _run('selection', Haptics.selection),
              ),
            ],
          ),
          const SizedBox(height: 22),

          _SectionLabel('Predefined OS effects'),
          const SizedBox(height: 10),
          _ChipRow(
            children: <Widget>[
              for (final PredefinedEffect effect in PredefinedEffect.values)
                ActionChip(
                  label: Text(effect.name),
                  onPressed: () =>
                      _run(effect.name, () => Vibration.playPredefined(effect)),
                ),
            ],
          ),
          const SizedBox(height: 22),

          _SectionLabel('Vibration'),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Amplitude',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text('${_amplitude.round()}', style: theme.textTheme.titleSmall),
            ],
          ),
          NovaSlider(
            value: _amplitude,
            min: 1,
            max: 255,
            divisions: 10,
            label: '${_amplitude.round()}',
            onChanged: (double v) => setState(() => _amplitude = v),
          ),
          const SizedBox(height: 8),
          _ChipRow(
            children: <Widget>[
              ActionChip(
                label: const Text('300 ms one-shot'),
                onPressed: () => _run(
                  'One-shot',
                  () => Vibration.vibrate(
                    duration: const Duration(milliseconds: 300),
                    amplitude: _amplitude.round(),
                  ),
                ),
              ),
              ActionChip(
                label: const Text('Rising waveform'),
                onPressed: () => _run(
                  'Waveform',
                  () => Vibration.vibrateWaveform(
                    timings: const <Duration>[
                      Duration.zero,
                      Duration(milliseconds: 100),
                      Duration(milliseconds: 100),
                      Duration(milliseconds: 100),
                      Duration(milliseconds: 100),
                      Duration(milliseconds: 100),
                    ],
                    amplitudes: const <int>[0, 80, 0, 160, 0, 255],
                  ),
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.stop_rounded, size: 16),
                label: const Text('Cancel'),
                onPressed: () => _run('Cancel', Vibration.cancel),
              ),
            ],
          ),
          const SizedBox(height: 22),

          _SectionLabel('Ready-made patterns'),
          const SizedBox(height: 10),
          _ChipRow(
            children: <Widget>[
              ActionChip(
                label: const Text('heartbeat'),
                onPressed: () => _run('heartbeat', VibrationPatterns.heartbeat),
              ),
              ActionChip(
                label: const Text('notification'),
                onPressed: () =>
                    _run('notification', VibrationPatterns.notification),
              ),
              ActionChip(
                label: const Text('alarm'),
                onPressed: () =>
                    _run('alarm', () => VibrationPatterns.alarm(repeat: false)),
              ),
              ActionChip(
                label: const Text('tick'),
                onPressed: () => _run('tick', VibrationPatterns.tick),
              ),
              ActionChip(
                label: const Text('doubleTap'),
                onPressed: () => _run('doubleTap', VibrationPatterns.doubleTap),
              ),
              ActionChip(
                label: const Text('success'),
                onPressed: () => _run('success', VibrationPatterns.success),
              ),
              ActionChip(
                label: const Text('failure'),
                onPressed: () => _run('failure', VibrationPatterns.failure),
              ),
              ActionChip(
                label: const Text('chargeUp'),
                onPressed: () => _run('chargeUp', VibrationPatterns.chargeUp),
              ),
            ],
          ),
          const SizedBox(height: 22),

          _SectionLabel('Custom Core Haptics pattern'),
          const SizedBox(height: 6),
          Text(
            'Two transient taps of rising sharpness, then a soft continuous '
            'swell — built with HapticPattern.builder().',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _run(
              'Custom pattern',
              () => HapticPattern.builder()
                  .tap(intensity: 0.4, sharpness: 0.6)
                  .pause(const Duration(milliseconds: 80))
                  .tap(intensity: 1, sharpness: 0.9)
                  .continuous(
                    duration: const Duration(milliseconds: 250),
                    intensity: 0.7,
                    sharpness: 0.3,
                  )
                  .play(),
            ),
            icon: const Icon(Icons.graphic_eq_rounded, size: 20),
            label: const Text('Play custom pattern'),
          ),
          const SizedBox(height: 32),

          Text('Widgets', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'The same components the shop uses.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),

          _Demo(
            title: 'Bounce',
            caption: 'Squash, recoil, elastic settle',
            child: NovaBounce(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  'Press me',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
          _Demo(
            title: 'Toggle',
            caption: 'Tick on flip',
            child: NovaToggle(
              value: _demoToggle,
              onChanged: (bool v) => setState(() => _demoToggle = v),
            ),
          ),
          _Demo(
            title: 'Slider',
            caption: 'Tick per detent, firmer at the ends',
            child: SizedBox(
              width: 220,
              child: NovaSlider(
                value: _demoSlider,
                min: 0,
                max: 100,
                divisions: 10,
                label: '${_demoSlider.round()}',
                onChanged: (double v) => setState(() => _demoSlider = v),
              ),
            ),
          ),
          _Demo(
            title: 'Stepper',
            caption: 'Bouncing −/+ buttons',
            child: NovaStepper(
              value: _demoStepper,
              max: 10,
              onChanged: (int v) => setState(() => _demoStepper = v),
            ),
          ),
          _Demo(
            title: 'Rating',
            caption: 'Cascading fill, one tick per star',
            child: NovaRating(
              value: _demoRating,
              size: 30,
              onChanged: (int v) => setState(() => _demoRating = v),
            ),
          ),
          _Demo(
            title: 'Shake',
            caption: 'Error wiggle, triggered externally',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                HapticShake(
                  key: _shakeKey,
                  haptics: haptics.isOn(HapticChannel.notifications),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _shakeKey.currentState?.shake(),
                  child: const Text('Shake'),
                ),
              ],
            ),
          ),
          _Demo(
            title: 'Pulse',
            caption: 'Breathing loop, tick per beat',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                HapticPulse(
                  key: _pulseKey,
                  autoPlay: false,
                  pulseCount: 4,
                  haptics: haptics.isOn(HapticChannel.selection),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _pulseKey.currentState?.start(),
                  child: const Text('Pulse ×4'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionLabel('Slide to confirm'),
          const SizedBox(height: 10),
          NovaSlideToConfirm(
            label: 'Slide to try',
            fallbackLabel: 'Confirm',
            onConfirmed: () => _toast('Confirmed'),
          ),
          const SizedBox(height: 22),
          _SectionLabel('Hold to confirm'),
          const SizedBox(height: 10),
          NovaHoldToConfirm(
            label: 'confirm',
            icon: Icons.fingerprint_rounded,
            onConfirm: () => _toast('Held to confirm'),
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

class _CapabilitiesCard extends ConsumerWidget {
  const _CapabilitiesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<HapticCapabilities?> caps = ref.watch(
      hapticCapabilitiesProvider,
    );

    return _Card(
      children: <Widget>[
        switch (caps) {
          AsyncLoading<HapticCapabilities?>() => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          AsyncData<HapticCapabilities?>(value: final HapticCapabilities c) =>
            Column(
              children: <Widget>[
                _CapRow('Vibrator', c.hasVibrator),
                _CapRow('Amplitude control', c.hasAmplitudeControl),
                _CapRow('Custom patterns', c.supportsCustomPatterns),
                _CapRow('Predefined effects', c.supportsPredefinedEffects),
                _CapRow('Impact feedback', c.supportsImpactFeedback),
              ],
            ),
          _ => Text(
            'Capabilities unavailable on this platform.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        },
      ],
    );
  }
}

class _CapRow extends StatelessWidget {
  const _CapRow(this.label, this.supported);

  final String label;
  final bool supported;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(
            supported
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline,
            size: 18,
            color: supported
                ? AppTheme.success
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            supported ? 'Yes' : 'No',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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

/// Wrapping row of playground trigger chips.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: children);
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

class _Demo extends StatelessWidget {
  const _Demo({
    required this.title,
    required this.caption,
    required this.child,
  });

  final String title;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          child,
        ],
      ),
    );
  }
}
