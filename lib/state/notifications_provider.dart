import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app_providers.dart';

/// Notification categories the shopper can switch independently.
enum NotifyChannel {
  orders(
    'Order updates',
    'Confirmations, shipping and delivery',
    'orders',
    'Order updates',
  ),
  deals(
    'Deals & price drops',
    'When something you saved goes on sale',
    'deals',
    'Deals',
  ),
  reminders(
    'Bag reminders',
    'A nudge when you leave something behind',
    'reminders',
    'Reminders',
  );

  const NotifyChannel(this.label, this.description, this.id, this.osName);

  final String label;
  final String description;

  /// Android channel id — stable, since renaming one orphans user settings.
  final String id;
  final String osName;
}

@immutable
class NotificationSettings {
  const NotificationSettings({
    this.enabled = true,
    this.channels = const <NotifyChannel>{
      NotifyChannel.orders,
      NotifyChannel.deals,
      NotifyChannel.reminders,
    },
  });

  final bool enabled;
  final Set<NotifyChannel> channels;

  bool isOn(NotifyChannel channel) => enabled && channels.contains(channel);

  NotificationSettings copyWith({
    bool? enabled,
    Set<NotifyChannel>? channels,
  }) => NotificationSettings(
    enabled: enabled ?? this.enabled,
    channels: channels ?? this.channels,
  );
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const String _enabledKey = 'notifications.enabled';
  static const String _channelsKey = 'notifications.channels';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  NotificationSettings build() {
    final SharedPreferences prefs = _prefs;
    final List<String>? stored = prefs.getStringList(_channelsKey);
    return NotificationSettings(
      enabled: prefs.getBool(_enabledKey) ?? true,
      channels: stored == null
          ? NotifyChannel.values.toSet()
          : <NotifyChannel>{
              for (final NotifyChannel c in NotifyChannel.values)
                if (stored.contains(c.name)) c,
            },
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await _prefs.setBool(_enabledKey, value);
  }

  Future<void> setChannel(NotifyChannel channel, bool on) async {
    final Set<NotifyChannel> next = <NotifyChannel>{...state.channels};
    if (on) {
      next.add(channel);
    } else {
      next.remove(channel);
    }
    state = state.copyWith(channels: next);
    await _prefs.setStringList(
      _channelsKey,
      next.map((NotifyChannel c) => c.name).toList(),
    );
  }
}

final NotifierProvider<NotificationSettingsNotifier, NotificationSettings>
notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );

final Provider<FlutterLocalNotificationsPlugin> notificationPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>(
      (Ref ref) => FlutterLocalNotificationsPlugin(),
    );

/// Sends local notifications, gated the same way haptics and biometrics are:
/// platform-guarded, never throwing, and honouring the shopper's settings.
class NotificationService {
  NotificationService(this._plugin, this._settings);

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationSettings _settings;

  static bool _initialized = false;
  static bool _timezonesReady = false;

  /// The plugin also has desktop implementations, but the app only configures
  /// and tests the mobile ones.
  static bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool isOn(NotifyChannel channel) =>
      platformSupported && _settings.isOn(channel);

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Runs a platform call, swallowing anything it throws.
  ///
  /// Catches [Object], not just [Exception], on purpose: when the plugin isn't
  /// registered — under `flutter test`, or on a platform that has no
  /// implementation — resolving it raises a `LateInitializationError`, which
  /// is an [Error] and slips past an `on Exception` clause. Notifications are
  /// decorative; letting one take down an order placement is not acceptable.
  Future<T?> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      debugPrint('notifications unavailable: $error');
      return null;
    }
  }

  /// Sets up channels and the timezone database. Safe to call repeatedly.
  Future<void> ensureInitialized() async {
    if (!platformSupported || _initialized) return;
    await _guard(() async {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            // Deliberately not requested at launch — the settings screen asks
            // when the shopper opts in, which is the moment it makes sense.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );

      for (final NotifyChannel channel in NotifyChannel.values) {
        await _android?.createNotificationChannel(
          AndroidNotificationChannel(
            channel.id,
            channel.osName,
            description: channel.description,
            importance: Importance.defaultImportance,
          ),
        );
      }
      _initialized = true;
    });
  }

  /// True once the OS has granted permission.
  Future<bool> hasPermission() async {
    if (!platformSupported) return false;
    return await _guard(() async {
          if (defaultTargetPlatform == TargetPlatform.android) {
            return await _android?.areNotificationsEnabled() ?? false;
          }
          final IOSFlutterLocalNotificationsPlugin? ios = _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
          final NotificationsEnabledOptions? options = await ios
              ?.checkPermissions();
          return options?.isEnabled ?? false;
        }) ??
        false;
  }

  /// Asks the OS for permission. Android 13+ and iOS both prompt once.
  Future<bool> requestPermission() async {
    if (!platformSupported) return false;
    await ensureInitialized();
    return await _guard(() async {
          if (defaultTargetPlatform == TargetPlatform.android) {
            return await _android?.requestNotificationsPermission() ?? false;
          }
          final IOSFlutterLocalNotificationsPlugin? ios = _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
          return await ios?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
              false;
        }) ??
        false;
  }

  NotificationDetails _details(NotifyChannel channel) => NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.osName,
      channelDescription: channel.description,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  /// Posts immediately. Silently does nothing when the channel is muted.
  Future<void> show({
    required NotifyChannel channel,
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!isOn(channel)) return;
    await ensureInitialized();
    await _guard(
      () => _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details(channel),
        payload: payload,
      ),
    );
  }

  /// Posts after [delay]. Falls back to nothing if scheduling is refused —
  /// exact-alarm permission is not something to nag a shopper for.
  Future<void> scheduleIn({
    required NotifyChannel channel,
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    if (!isOn(channel)) return;
    await ensureInitialized();
    if (!_timezonesReady) {
      tz_data.initializeTimeZones();
      _timezonesReady = true;
    }
    await _guard(
      () => _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
        notificationDetails: _details(channel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      ),
    );
  }

  Future<void> cancelAll() async {
    if (!platformSupported) return;
    await _guard(_plugin.cancelAll);
  }

  /// Order-lifecycle messages: one now, two scheduled to mirror the status
  /// tracker on the order screen.
  Future<void> announceOrder({
    required String orderId,
    required int itemCount,
    required String total,
  }) async {
    final int base = orderId.hashCode.abs() % 100000;
    await show(
      channel: NotifyChannel.orders,
      id: base,
      title: 'Order confirmed',
      body:
          '$orderId · $itemCount ${itemCount == 1 ? 'item' : 'items'} · $total',
      payload: orderId,
    );
    await scheduleIn(
      channel: NotifyChannel.orders,
      id: base + 1,
      title: 'Your order has shipped',
      body: '$orderId is on its way.',
      delay: const Duration(hours: 8),
      payload: orderId,
    );
    await scheduleIn(
      channel: NotifyChannel.orders,
      id: base + 2,
      title: 'Delivered',
      body: '$orderId should have arrived. Enjoy!',
      delay: const Duration(days: 4),
      payload: orderId,
    );
  }
}

final Provider<NotificationService> notificationsProvider =
    Provider<NotificationService>(
      (Ref ref) => NotificationService(
        ref.watch(notificationPluginProvider),
        ref.watch(notificationSettingsProvider),
      ),
    );

/// Live OS permission state for the settings screen.
final FutureProvider<bool> notificationPermissionProvider =
    FutureProvider<bool>(
      (Ref ref) => ref.watch(notificationsProvider).hasPermission(),
    );
