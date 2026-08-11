import 'package:ecommerce_app/state/notifications_provider.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The plugin talks to the platform over these channels; recording them is
  /// the only way to assert that a muted channel really sends nothing.
  List<MethodCall> installRecorder() {
    final List<MethodCall> calls = <MethodCall>[];
    for (final String name in <String>[
      'dexterous.com/flutter/local_notifications',
      'dexterx.dev/flutter_local_notifications',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (
            MethodCall call,
          ) async {
            calls.add(call);
            return null;
          });
    }
    return calls;
  }

  group('settings', () {
    test('default to everything on', () async {
      final ProviderContainer c = await testContainer();
      final NotificationSettings s = c.read(notificationSettingsProvider);
      expect(s.enabled, isTrue);
      expect(s.channels, NotifyChannel.values.toSet());
      for (final NotifyChannel channel in NotifyChannel.values) {
        expect(s.isOn(channel), isTrue);
      }
    });

    test('master switch overrides individual channels', () async {
      final ProviderContainer c = await testContainer();
      await c.read(notificationSettingsProvider.notifier).setEnabled(false);
      final NotificationSettings s = c.read(notificationSettingsProvider);
      for (final NotifyChannel channel in NotifyChannel.values) {
        expect(s.isOn(channel), isFalse, reason: channel.name);
      }
    });

    test('a single channel can be muted', () async {
      final ProviderContainer c = await testContainer();
      await c
          .read(notificationSettingsProvider.notifier)
          .setChannel(NotifyChannel.deals, false);

      final NotificationSettings s = c.read(notificationSettingsProvider);
      expect(s.isOn(NotifyChannel.deals), isFalse);
      expect(s.isOn(NotifyChannel.orders), isTrue);
    });

    test('restores from storage', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: const <String, Object>{
          'notifications.enabled': true,
          'notifications.channels': <String>['orders'],
        },
      );
      final NotificationSettings s = c.read(notificationSettingsProvider);
      expect(s.channels, <NotifyChannel>{NotifyChannel.orders});
      expect(s.isOn(NotifyChannel.reminders), isFalse);
    });

    test('channel ids are stable and unique', () {
      final Set<String> ids = NotifyChannel.values
          .map((NotifyChannel c) => c.id)
          .toSet();
      expect(ids, hasLength(NotifyChannel.values.length));
      expect(ids, containsAll(<String>['orders', 'deals', 'reminders']));
    });
  });

  group('gating', () {
    test('muted channels reach the platform never', () async {
      final List<MethodCall> calls = installRecorder();
      final NotificationService service = NotificationService(
        FlutterLocalNotificationsPlugin(),
        const NotificationSettings(enabled: false),
      );

      await service.show(
        channel: NotifyChannel.orders,
        id: 1,
        title: 't',
        body: 'b',
      );
      await service.announceOrder(orderId: 'X', itemCount: 1, total: r'$1');

      expect(calls.where((MethodCall c) => c.method == 'show'), isEmpty);
    });

    test('isOn mirrors the settings on a supported platform', () {
      final NotificationService service = NotificationService(
        FlutterLocalNotificationsPlugin(),
        const NotificationSettings(
          channels: <NotifyChannel>{NotifyChannel.orders},
        ),
      );
      expect(service.isOn(NotifyChannel.orders), isTrue);
      expect(service.isOn(NotifyChannel.deals), isFalse);
    });
  });

  group('platform guard', () {
    test('never touches the platform off Android/iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final List<MethodCall> calls = installRecorder();
      final NotificationService service = NotificationService(
        FlutterLocalNotificationsPlugin(),
        const NotificationSettings(),
      );

      expect(NotificationService.platformSupported, isFalse);
      await service.ensureInitialized();
      await service.show(
        channel: NotifyChannel.orders,
        id: 1,
        title: 't',
        body: 'b',
      );
      await service.cancelAll();
      expect(await service.hasPermission(), isFalse);
      expect(await service.requestPermission(), isFalse);

      expect(calls, isEmpty);
    });
  });

  group('failure containment', () {
    test('an unregistered plugin never throws', () async {
      // No mock handler at all: resolving the plugin raises a
      // LateInitializationError, which is an Error rather than an Exception.
      final NotificationService service = NotificationService(
        FlutterLocalNotificationsPlugin(),
        const NotificationSettings(),
      );

      await expectLater(
        service.announceOrder(orderId: 'NV-1', itemCount: 2, total: r'$40'),
        completes,
      );
      await expectLater(service.cancelAll(), completes);
      expect(await service.hasPermission(), isFalse);
      expect(await service.requestPermission(), isFalse);
    });
  });
}
