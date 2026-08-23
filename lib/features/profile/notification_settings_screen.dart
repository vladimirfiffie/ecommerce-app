import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../../shared/widgets/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../state/notifications_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key, this.embedded = false});

  /// Shown inside the settings detail pane, where a back button
  /// would have nothing to pop.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NotificationSettings settings = ref.watch(
      notificationSettingsProvider,
    );
    final NotificationSettingsNotifier notifier = ref.read(
      notificationSettingsProvider.notifier,
    );
    final AsyncValue<bool> permission = ref.watch(
      notificationPermissionProvider,
    );
    final bool granted = permission.value ?? false;
    final bool supported = NotificationService.platformSupported;

    Future<void> toast(String message) async {
      if (!context.mounted) return;
      showMessage(context, message);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        automaticallyImplyLeading: !embedded,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  !supported
                      ? Icons.desktop_access_disabled_outlined
                      : granted
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  size: 26,
                  color: granted
                      ? AppTheme.success
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        !supported
                            ? 'Not available here'
                            : granted
                            ? 'Allowed'
                            : 'Not allowed yet',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        !supported
                            ? 'Notifications need Android or iOS'
                            : granted
                            ? 'The system will deliver Aster’s notifications'
                            : 'Grant permission to receive order updates',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (supported && !granted) ...<Widget>[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final bool ok = await ref
                    .read(notificationsProvider)
                    .requestPermission();
                ref.invalidate(notificationPermissionProvider);
                await toast(ok ? 'Notifications allowed' : 'Permission denied');
              },
              icon: const Icon(Icons.notifications_rounded, size: 20),
              label: const Text('Allow notifications'),
            ),
          ],
          const SizedBox(height: 24),

          AdaptiveListTile(
            padding: EdgeInsets.zero,
            hideBottomDivider: true,
            title: const Text('Notifications'),
            subtitle: const Text('Master switch for everything below'),
            onTap: () => notifier.setEnabled(!settings.enabled),
            trailing: AdaptiveSwitch(
              value: settings.enabled,
              onChanged: notifier.setEnabled,
            ),
          ),
          const Divider(height: 24),
          for (final NotifyChannel channel in NotifyChannel.values)
            AdaptiveListTile(
              padding: EdgeInsets.zero,
              hideBottomDivider: true,
              title: Text(channel.label),
              subtitle: Text(channel.description),
              // A channel means nothing with the master switch off.
              enabled: settings.enabled,
              onTap: settings.enabled
                  ? () => notifier.setChannel(
                      channel,
                      !settings.channels.contains(channel),
                    )
                  : null,
              trailing: AdaptiveSwitch(
                value: settings.channels.contains(channel),
                onChanged: settings.enabled
                    ? (bool v) => notifier.setChannel(channel, v)
                    : (bool _) {},
              ),
            ),
          const SizedBox(height: 26),

          Text('Try it', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ActionChip(
                avatar: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send a test'),
                onPressed: () async {
                  await ref
                      .read(notificationsProvider)
                      .show(
                        channel: NotifyChannel.orders,
                        id: 999001,
                        title: 'Aster',
                        body: 'This is what an order update looks like.',
                      );
                  await toast(
                    !supported
                        ? 'Not available on this platform'
                        : settings.isOn(NotifyChannel.orders)
                        ? 'Sent'
                        : 'Order updates are switched off',
                  );
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.schedule_rounded, size: 16),
                label: const Text('Schedule in 10s'),
                onPressed: () async {
                  await ref
                      .read(notificationsProvider)
                      .scheduleIn(
                        channel: NotifyChannel.deals,
                        id: 999002,
                        title: 'Price drop',
                        body: 'Something you saved just went on sale.',
                        delay: const Duration(seconds: 10),
                      );
                  await toast(
                    !supported
                        ? 'Not available on this platform'
                        : settings.isOn(NotifyChannel.deals)
                        ? 'Scheduled for 10 seconds from now'
                        : 'Deals are switched off',
                  );
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Cancel all'),
                onPressed: () async {
                  await ref.read(notificationsProvider).cancelAll();
                  await toast('Cleared');
                },
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Placing an order sends a confirmation right away, then shipping '
            'and delivery updates on a schedule that mirrors the order '
            'tracker. Everything is generated on this device — there is no '
            'server pushing to you.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
