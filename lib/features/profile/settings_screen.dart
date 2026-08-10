import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../state/cart_provider.dart';
import '../../state/catalog_filter_provider.dart';
import '../../state/favorites_provider.dart';
import '../../state/orders_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/haptics_provider.dart';
import '../../core/router/app_router.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Material You palettes only exist on Android 12+.
  bool get _dynamicColorSupported => !kIsWeb && Platform.isAndroid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    final HapticSettings haptics = ref.watch(hapticSettingsProvider);
    final String hapticSummary = !HapticService.platformSupported
        ? 'Not available on this platform'
        : !haptics.enabled
        ? 'Off'
        : '${haptics.intensity.label} · '
              '${haptics.channels.length} of ${HapticChannel.values.length} on';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: <Widget>[
          Text('Appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 14),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded),
                label: Text('Light'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded),
                label: Text('Auto'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded),
                label: Text('Dark'),
              ),
            ],
            selected: <ThemeMode>{settings.themeMode},
            onSelectionChanged: (Set<ThemeMode> selection) =>
                notifier.setThemeMode(selection.first),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Match my wallpaper'),
            subtitle: Text(
              _dynamicColorSupported
                  ? 'Use the Material You palette from your home screen'
                  : 'Only available on Android 12 and newer',
            ),
            value: settings.useDynamicColor && _dynamicColorSupported,
            onChanged: _dynamicColorSupported ? notifier.setDynamicColor : null,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Grid view by default'),
            subtitle: const Text('How the Shop tab lays out results'),
            value: settings.gridView,
            onChanged: notifier.setGridView,
          ),
          const SizedBox(height: 18),
          Text('Feedback', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.vibration_rounded),
            title: Text('Haptics', style: theme.textTheme.titleSmall),
            subtitle: Text(hapticSummary, style: theme.textTheme.bodySmall),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.haptics),
          ),
          const SizedBox(height: 26),
          Text('Your data', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Everything in this build is stored on this device only — there '
            'is no account and nothing is uploaded.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          _DangerTile(
            icon: Icons.history_rounded,
            label: 'Clear browsing history',
            description: 'Recent searches and recently viewed items',
            onConfirm: () {
              ref.read(searchHistoryProvider.notifier).clear();
              ref.read(recentlyViewedProvider.notifier).clear();
            },
          ),
          _DangerTile(
            icon: Icons.delete_sweep_outlined,
            label: 'Reset everything',
            description: 'Bag, wishlist, orders and history',
            destructive: true,
            onConfirm: () {
              ref.read(cartProvider.notifier).clear();
              ref.read(favoritesProvider.notifier).clear();
              ref.read(ordersProvider.notifier).clear();
              ref.read(searchHistoryProvider.notifier).clear();
              ref.read(recentlyViewedProvider.notifier).clear();
              ref.read(appliedPromoProvider.notifier).clear();
            },
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('About Nova', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  'A Flutter storefront demo. Product data ships with the app; '
                  'imagery is loaded and cached from a public CDN.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Version 0.1.0 · prerelease',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onConfirm,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onConfirm;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(color: color),
      ),
      subtitle: Text(description, style: theme.textTheme.bodySmall),
      onTap: () async {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('$label?'),
            content: Text('$description will be removed from this device.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
        if (!(confirmed ?? false)) return;
        onConfirm();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('Done')));
      },
    );
  }
}
