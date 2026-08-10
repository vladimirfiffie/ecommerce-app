import 'package:ecommerce_app/state/haptics_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_kit/haptic_kit.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('dev.erykkruk/haptic_kit');

  /// Records what actually reached the platform.
  List<MethodCall> installRecorder({bool failWith = false}) {
    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          if (failWith) {
            throw PlatformException(code: 'unsupported', message: 'nope');
          }
          if (call.method == 'capabilities.query') {
            return <Object?, Object?>{
              'hasVibrator': true,
              'hasAmplitudeControl': false,
              'supportsCustomPatterns': true,
              'supportsPredefinedEffects': false,
              'supportsImpactFeedback': true,
            };
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    return calls;
  }

  group('intensity scaling', () {
    HapticService serviceAt(HapticIntensity intensity) =>
        HapticService(HapticSettings(intensity: intensity));

    test('subtle shifts one rung down, strong one up', () {
      expect(
        serviceAt(HapticIntensity.subtle).scale(HapticImpactStyle.medium),
        HapticImpactStyle.light,
      );
      expect(
        serviceAt(HapticIntensity.standard).scale(HapticImpactStyle.medium),
        HapticImpactStyle.medium,
      );
      expect(
        serviceAt(HapticIntensity.strong).scale(HapticImpactStyle.medium),
        HapticImpactStyle.heavy,
      );
    });

    test('clamps at the ends of the ladder', () {
      expect(
        serviceAt(HapticIntensity.subtle).scale(HapticImpactStyle.light),
        HapticImpactStyle.light,
      );
      expect(
        serviceAt(HapticIntensity.strong).scale(HapticImpactStyle.heavy),
        HapticImpactStyle.heavy,
      );
    });

    test('leaves iOS-only styles untouched — they have no rung', () {
      for (final HapticIntensity i in HapticIntensity.values) {
        expect(
          serviceAt(i).scale(HapticImpactStyle.soft),
          HapticImpactStyle.soft,
        );
        expect(
          serviceAt(i).scale(HapticImpactStyle.rigid),
          HapticImpactStyle.rigid,
        );
      }
    });
  });

  group('gating', () {
    test('master switch off suppresses every channel', () async {
      final List<MethodCall> calls = installRecorder();
      const HapticService service = HapticService(
        HapticSettings(enabled: false),
      );

      await service.impact();
      await service.selection();
      await service.notification(HapticNotificationStyle.success);
      await service.vibrate(duration: const Duration(milliseconds: 100));
      await service.heartbeat();

      expect(calls, isEmpty);
    });

    test('a muted channel blocks only its own calls', () async {
      final List<MethodCall> calls = installRecorder();
      const HapticService service = HapticService(
        HapticSettings(
          channels: <HapticChannel>{
            HapticChannel.buttons,
            HapticChannel.notifications,
          },
        ),
      );

      await service.impact(); // buttons — allowed
      await service.selection(); // selection — muted
      await service.notification(HapticNotificationStyle.error); // allowed
      await service.heartbeat(); // vibrations — muted

      expect(calls.map((MethodCall c) => c.method).toList(), <String>[
        'haptic.impact',
        'haptic.notification',
      ]);
    });

    test('everything on lets each call through', () async {
      final List<MethodCall> calls = installRecorder();
      const HapticService service = HapticService(HapticSettings());

      await service.impact();
      await service.selection();
      await service.notification(HapticNotificationStyle.warning);
      await service.predefined(PredefinedEffect.tick);
      await service.vibrate(duration: const Duration(milliseconds: 50));

      expect(calls, hasLength(5));
    });
  });

  group('failure containment', () {
    test('a rejecting platform never surfaces an exception', () async {
      installRecorder(failWith: true);
      const HapticService service = HapticService(HapticSettings());

      // Each of these would throw if the service didn't swallow.
      await expectLater(service.impact(), completes);
      await expectLater(service.selection(), completes);
      await expectLater(service.success(), completes);
      await expectLater(service.cancel(), completes);
      await expectLater(
        service.vibrate(duration: const Duration(milliseconds: 10)),
        completes,
      );
      expect(await service.prepare(), isFalse);
    });

    test('invalid arguments are contained too', () async {
      installRecorder();
      const HapticService service = HapticService(HapticSettings());
      // Zero duration throws InvalidVibrationArgumentException inside the
      // package before it ever reaches the channel.
      await expectLater(service.vibrate(duration: Duration.zero), completes);
    });
  });

  group('platform guard', () {
    test('drops calls where the plugin has no implementation', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final List<MethodCall> calls = installRecorder();
      const HapticService service = HapticService(HapticSettings());

      expect(HapticService.platformSupported, isFalse);
      await service.impact();
      await service.heartbeat();
      await service.selection();

      expect(calls, isEmpty);
    });

    test('capabilities resolve to null off-platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      installRecorder();

      final ProviderContainer c = await testContainer();
      expect(await c.read(hapticCapabilitiesProvider.future), isNull);
    });

    test('capabilities are read through on a supported platform', () async {
      installRecorder();
      final ProviderContainer c = await testContainer();

      final HapticCapabilities? caps = await c.read(
        hapticCapabilitiesProvider.future,
      );
      expect(caps, isNotNull);
      expect(caps!.hasVibrator, isTrue);
      expect(caps.hasAmplitudeControl, isFalse);
      expect(caps.supportsCustomPatterns, isTrue);
    });
  });

  group('settings persistence', () {
    test('defaults to fully enabled', () async {
      final ProviderContainer c = await testContainer();
      final HapticSettings s = c.read(hapticSettingsProvider);
      expect(s.enabled, isTrue);
      expect(s.intensity, HapticIntensity.standard);
      expect(s.channels, HapticChannel.values.toSet());
    });

    test('writes each preference to storage', () async {
      final ProviderContainer c = await testContainer();
      final HapticSettingsNotifier n = c.read(hapticSettingsProvider.notifier);

      await n.setIntensity(HapticIntensity.strong);
      await n.setChannel(HapticChannel.selection, false);
      await n.setEnabled(false);

      final HapticSettings s = c.read(hapticSettingsProvider);
      expect(s.enabled, isFalse);
      expect(s.intensity, HapticIntensity.strong);
      expect(s.channels, isNot(contains(HapticChannel.selection)));
      expect(s.channels, contains(HapticChannel.buttons));
    });

    test('restores from stored preferences', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: const <String, Object>{
          'haptics.enabled': true,
          'haptics.intensity': 'subtle',
          'haptics.channels': <String>['buttons', 'notifications'],
        },
      );

      final HapticSettings s = c.read(hapticSettingsProvider);
      expect(s.intensity, HapticIntensity.subtle);
      expect(s.channels, <HapticChannel>{
        HapticChannel.buttons,
        HapticChannel.notifications,
      });
      expect(s.isOn(HapticChannel.buttons), isTrue);
      expect(s.isOn(HapticChannel.selection), isFalse);
    });

    test(
      'isOn is false for every channel once the master switch is off',
      () async {
        final ProviderContainer c = await testContainer(
          initialPrefs: const <String, Object>{'haptics.enabled': false},
        );
        final HapticSettings s = c.read(hapticSettingsProvider);
        for (final HapticChannel channel in HapticChannel.values) {
          expect(s.isOn(channel), isFalse, reason: channel.name);
        }
      },
    );
  });
}
