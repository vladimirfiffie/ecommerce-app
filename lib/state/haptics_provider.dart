import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_kit/haptic_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';

/// Overall strength of every tap the app produces.
enum HapticIntensity {
  subtle('Subtle', 'Barely-there taps'),
  standard('Standard', 'Balanced, the default'),
  strong('Strong', 'Firm and obvious');

  const HapticIntensity(this.label, this.description);

  final String label;
  final String description;
}

/// Independently switchable groups, so a shopper can keep confirmations but
/// silence the chattier per-step ticks.
enum HapticChannel {
  buttons('Buttons & taps', 'Add to bag, checkout, card presses'),
  selection('Selection ticks', 'Chips, steppers, sliders, star ratings'),
  notifications('Confirmations', 'Order placed, validation errors'),
  vibrations('Long vibrations', 'Order confirmation and alert patterns');

  const HapticChannel(this.label, this.description);

  final String label;
  final String description;
}

@immutable
class HapticSettings {
  const HapticSettings({
    this.enabled = true,
    this.intensity = HapticIntensity.standard,
    this.channels = const <HapticChannel>{
      HapticChannel.buttons,
      HapticChannel.selection,
      HapticChannel.notifications,
      HapticChannel.vibrations,
    },
  });

  final bool enabled;
  final HapticIntensity intensity;
  final Set<HapticChannel> channels;

  bool isOn(HapticChannel channel) => enabled && channels.contains(channel);

  HapticSettings copyWith({
    bool? enabled,
    HapticIntensity? intensity,
    Set<HapticChannel>? channels,
  }) => HapticSettings(
    enabled: enabled ?? this.enabled,
    intensity: intensity ?? this.intensity,
    channels: channels ?? this.channels,
  );
}

class HapticSettingsNotifier extends Notifier<HapticSettings> {
  static const String _enabledKey = 'haptics.enabled';
  static const String _intensityKey = 'haptics.intensity';
  static const String _channelsKey = 'haptics.channels';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  HapticSettings build() {
    final SharedPreferences prefs = _prefs;
    final List<String>? stored = prefs.getStringList(_channelsKey);
    return HapticSettings(
      enabled: prefs.getBool(_enabledKey) ?? true,
      intensity: HapticIntensity.values.firstWhere(
        (HapticIntensity i) => i.name == prefs.getString(_intensityKey),
        orElse: () => HapticIntensity.standard,
      ),
      channels: stored == null
          ? HapticChannel.values.toSet()
          : <HapticChannel>{
              for (final HapticChannel c in HapticChannel.values)
                if (stored.contains(c.name)) c,
            },
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await _prefs.setBool(_enabledKey, value);
  }

  Future<void> setIntensity(HapticIntensity value) async {
    state = state.copyWith(intensity: value);
    await _prefs.setString(_intensityKey, value.name);
  }

  Future<void> setChannel(HapticChannel channel, bool on) async {
    final Set<HapticChannel> next = <HapticChannel>{...state.channels};
    if (on) {
      next.add(channel);
    } else {
      next.remove(channel);
    }
    state = state.copyWith(channels: next);
    await _prefs.setStringList(
      _channelsKey,
      next.map((HapticChannel c) => c.name).toList(),
    );
  }
}

final NotifierProvider<HapticSettingsNotifier, HapticSettings>
hapticSettingsProvider =
    NotifierProvider<HapticSettingsNotifier, HapticSettings>(
      HapticSettingsNotifier.new,
    );

/// Every haptic in the app goes through here.
///
/// Three things this guarantees that calling `haptic_kit` directly does not:
///
/// * **Platform safety** — the plugin only has Android and iOS
///   implementations and throws `PlatformVibrationException` everywhere else,
///   so calls are dropped off-platform instead of blowing up desktop and tests.
/// * **Never throws** — feedback is decorative; a failed tap must not take a
///   checkout down with it.
/// * **Respects the shopper's settings** — master switch, per-channel toggles
///   and the global intensity scale.
class HapticService {
  const HapticService(this.settings);

  final HapticSettings settings;

  /// The plugin ships Android and iOS implementations only.
  static bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool isOn(HapticChannel channel) =>
      platformSupported && settings.isOn(channel);

  /// Shifts a style up or down the scale to match the intensity preference.
  HapticImpactStyle scale(HapticImpactStyle style) {
    const List<HapticImpactStyle> ladder = <HapticImpactStyle>[
      HapticImpactStyle.light,
      HapticImpactStyle.medium,
      HapticImpactStyle.heavy,
    ];
    // soft/rigid are iOS-only variants with no meaningful rung on the ladder.
    final int base = ladder.indexOf(style);
    if (base < 0) return style;
    final int shift = switch (settings.intensity) {
      HapticIntensity.subtle => -1,
      HapticIntensity.standard => 0,
      HapticIntensity.strong => 1,
    };
    return ladder[(base + shift).clamp(0, ladder.length - 1)];
  }

  /// Runs [action] unless the channel is muted, swallowing plugin failures.
  Future<void> _guard(
    HapticChannel channel,
    Future<void> Function() action,
  ) async {
    if (!isOn(channel)) return;
    try {
      await action();
    } on VibrationException catch (error) {
      debugPrint('haptics unavailable: $error');
    }
  }

  Future<void> impact([HapticImpactStyle style = HapticImpactStyle.medium]) =>
      _guard(HapticChannel.buttons, () => Haptics.impact(scale(style)));

  Future<void> selection() =>
      _guard(HapticChannel.selection, Haptics.selection);

  Future<void> notification(HapticNotificationStyle style) =>
      _guard(HapticChannel.notifications, () => Haptics.notification(style));

  /// Pre-warms iOS generators so the first tap isn't late. No-op elsewhere.
  Future<bool> prepare() async {
    if (!platformSupported || !settings.enabled) return false;
    try {
      return await Haptics.prepare();
    } on VibrationException {
      return false;
    }
  }

  Future<void> vibrate({required Duration duration, int? amplitude}) => _guard(
    HapticChannel.vibrations,
    () => Vibration.vibrate(duration: duration, amplitude: amplitude),
  );

  Future<void> waveform({
    required List<Duration> timings,
    List<int>? amplitudes,
  }) => _guard(
    HapticChannel.vibrations,
    () => Vibration.vibrateWaveform(timings: timings, amplitudes: amplitudes),
  );

  Future<void> predefined(PredefinedEffect effect) =>
      _guard(HapticChannel.selection, () => Vibration.playPredefined(effect));

  Future<void> cancel() async {
    if (!platformSupported) return;
    try {
      await Vibration.cancel();
    } on VibrationException {
      /* nothing to cancel */
    }
  }

  Future<void> pattern(HapticPattern Function(HapticPattern) build) => _guard(
    HapticChannel.vibrations,
    () => build(HapticPattern.builder()).play(),
  );

  // Ready-made patterns, each on the vibrations channel.
  Future<void> heartbeat() =>
      _guard(HapticChannel.vibrations, VibrationPatterns.heartbeat);

  Future<void> notificationPattern() =>
      _guard(HapticChannel.vibrations, VibrationPatterns.notification);

  Future<void> alarm() => _guard(
    HapticChannel.vibrations,
    () => VibrationPatterns.alarm(repeat: false),
  );

  Future<void> tickPattern() =>
      _guard(HapticChannel.vibrations, VibrationPatterns.tick);

  Future<void> doubleTap() =>
      _guard(HapticChannel.vibrations, VibrationPatterns.doubleTap);

  Future<void> success() =>
      _guard(HapticChannel.vibrations, VibrationPatterns.success);

  Future<void> failure() =>
      _guard(HapticChannel.vibrations, VibrationPatterns.failure);

  Future<void> chargeUp({
    Duration duration = const Duration(milliseconds: 600),
  }) => _guard(
    HapticChannel.vibrations,
    () => VibrationPatterns.chargeUp(duration: duration),
  );
}

final Provider<HapticService> hapticsProvider = Provider<HapticService>(
  (Ref ref) => HapticService(ref.watch(hapticSettingsProvider)),
);

/// What the hardware can actually do. Null off-platform or when the query
/// fails — the settings screen renders that as "unavailable" rather than
/// pretending everything is supported.
final FutureProvider<HapticCapabilities?> hapticCapabilitiesProvider =
    FutureProvider<HapticCapabilities?>((Ref ref) async {
      if (!HapticService.platformSupported) return null;
      try {
        return await HapticCapabilities.query();
      } on VibrationException {
        return null;
      }
    });
