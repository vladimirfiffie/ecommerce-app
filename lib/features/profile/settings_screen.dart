import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../state/addresses_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/biometrics_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/catalog_filter_provider.dart';
import '../../state/favorites_provider.dart';
import '../../state/haptics_provider.dart';
import '../../state/notifications_provider.dart';
import '../../state/orders_provider.dart';
import '../../state/payments_provider.dart';
import '../../state/profile_provider.dart';
import '../../state/settings_provider.dart';
import 'widgets/edit_name_sheet.dart';
import 'widgets/settings_group.dart';
import 'widgets/theme_picker.dart';
import 'security_settings_screen.dart';
import 'payment_methods_screen.dart';
import 'notification_settings_screen.dart';
import 'haptics_settings_screen.dart';
import 'addresses_screen.dart';
import '../../core/layout/two_pane.dart';
import '../whats_new/whats_new_sheet.dart';
import '../../core/release_notes.dart';

/// Grouped settings.
///
/// This was a flat list of switches and tiles; the groups give each concern a
/// heading, and the shopping details (addresses, cards) now have real screens
/// instead of a sheet buried in Profile.
/// Which sub-screen the detail pane is showing.
enum SettingsPane { addresses, payments, haptics, notifications, security }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SettingsPane? _pane;

  /// Material You palettes only exist on Android 12+.
  bool get _dynamicColorSupported => !kIsWeb && Platform.isAndroid;

  /// Opens a sub-screen: in the pane on a tablet, as a route on a phone.
  void _open(SettingsPane pane, String route, bool twoPane) {
    if (twoPane) {
      setState(() => _pane = pane);
    } else {
      context.push(route);
    }
  }

  Widget _paneBody(SettingsPane pane) => switch (pane) {
    SettingsPane.addresses => const AddressesScreen(embedded: true),
    SettingsPane.payments => const PaymentMethodsScreen(embedded: true),
    SettingsPane.haptics => const HapticsSettingsScreen(embedded: true),
    SettingsPane.notifications => const NotificationSettingsScreen(
      embedded: true,
    ),
    SettingsPane.security => const SecuritySettingsScreen(embedded: true),
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    final HapticSettings haptics = ref.watch(hapticSettingsProvider);
    final bool signedIn = ref.watch(signedInProvider);

    final String hapticSummary = !HapticService.platformSupported
        ? 'Not available on this platform'
        : !haptics.enabled
        ? 'Off'
        : '${haptics.intensity.label} · '
              '${haptics.channels.length} of ${HapticChannel.values.length} on';

    final String name = ref.watch(displayNameProvider);
    final int addressCount = ref.watch(addressesProvider).length;
    final int cardCount = ref.watch(paymentCardsProvider).length;

    final bool twoPane = useTwoPane(context);

    final Widget master = ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: <Widget>[
        SettingsGroup(
          title: 'Account',
          children: <Widget>[
            SettingsRow(
              icon: Icons.badge_outlined,
              title: 'Name',
              subtitle: 'Nova greets you with this',
              trailing: _Value(name.isEmpty ? 'Not set' : name),
              onTap: () => showEditNameSheet(context),
            ),
            SettingsRow(
              icon: signedIn
                  ? Icons.verified_user_outlined
                  : Icons.login_rounded,
              title: signedIn ? 'Signed in' : 'Sign in or create an account',
              subtitle: signedIn
                  ? ref.watch(authProvider).account!.email
                  : 'Optional — everything works as a guest',
              onTap: signedIn ? null : () => context.push(Routes.signIn),
              // Signing out lives on Profile, with its confirmation —
              // having it in both places invited a stray tap here.
              trailing: signedIn
                  ? Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
          ],
        ),

        SettingsGroup(
          title: 'Shopping',
          children: <Widget>[
            SettingsRow(
              icon: Icons.location_on_outlined,
              title: 'Addresses',
              subtitle: '$addressCount saved',
              onTap: () =>
                  _open(SettingsPane.addresses, Routes.addresses, twoPane),
            ),
            SettingsRow(
              icon: Icons.credit_card_outlined,
              title: 'Payment methods',
              subtitle: cardCount == 0 ? 'No cards saved' : '$cardCount saved',
              onTap: () =>
                  _open(SettingsPane.payments, Routes.payments, twoPane),
            ),
            SettingsSwitch(
              icon: Icons.grid_view_rounded,
              title: 'Grid view by default',
              subtitle: 'How the Shop tab lays out results',
              value: settings.gridView,
              onChanged: notifier.setGridView,
            ),
          ],
        ),

        SettingsGroup(
          title: 'Appearance',
          caption: 'Presets are ignored while your wallpaper palette is on.',
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Mode', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
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
                    onSelectionChanged: (Set<ThemeMode> s) =>
                        notifier.setThemeMode(s.first),
                  ),
                  const SizedBox(height: 18),
                  Text('Colour', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ThemePicker(
                    dynamicActive:
                        settings.useDynamicColor && _dynamicColorSupported,
                  ),
                ],
              ),
            ),
            SettingsSwitch(
              icon: Icons.wallpaper_rounded,
              title: 'Match my wallpaper',
              subtitle: _dynamicColorSupported
                  ? 'Use the Material You palette'
                  : 'Android 12 and newer only',
              value: settings.useDynamicColor && _dynamicColorSupported,
              onChanged: _dynamicColorSupported
                  ? notifier.setDynamicColor
                  : null,
            ),
            SettingsSwitch(
              icon: Icons.contrast_rounded,
              title: 'AMOLED black',
              subtitle: 'True-black surfaces in dark mode',
              value: settings.amoled,
              onChanged: notifier.setAmoled,
            ),
          ],
        ),

        SettingsGroup(
          title: 'Feedback & alerts',
          children: <Widget>[
            SettingsRow(
              icon: Icons.vibration_rounded,
              title: 'Haptics',
              subtitle: hapticSummary,
              onTap: () => _open(SettingsPane.haptics, Routes.haptics, twoPane),
            ),
            SettingsRow(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: ref.watch(notificationSettingsProvider).enabled
                  ? 'Order updates, deals and reminders'
                  : 'Off',
              onTap: () => _open(
                SettingsPane.notifications,
                Routes.notifications,
                twoPane,
              ),
            ),
          ],
        ),

        SettingsGroup(
          title: 'Security',
          children: <Widget>[
            SettingsRow(
              icon: Icons.fingerprint_rounded,
              title: 'Payment verification',
              subtitle: ref.watch(requireBiometricsProvider)
                  ? 'Required before paying'
                  : 'Not required',
              onTap: () =>
                  _open(SettingsPane.security, Routes.security, twoPane),
            ),
          ],
        ),

        SettingsGroup(
          title: 'What’s new',
          caption: 'What changed in this build, and the ones before it.',
          children: <Widget>[
            SettingsRow(
              icon: Icons.new_releases_outlined,
              title: 'Release notes',
              subtitle: 'Version $currentReleaseVersion',
              onTap: () => showWhatsNewSheet(
                context,
                notes: kReleaseNotes,
                offerMute: false,
              ),
            ),
          ],
        ),

        SettingsGroup(
          title: 'Your data',
          caption:
              'Everything in this build is stored on this device only — '
              'there is no server and nothing is uploaded.',
          children: <Widget>[
            _DangerRow(
              icon: Icons.history_rounded,
              label: 'Clear browsing history',
              description: 'Recent searches and recently viewed items',
              onConfirm: () {
                ref.read(searchHistoryProvider.notifier).clear();
                ref.read(recentlyViewedProvider.notifier).clear();
              },
            ),
            _DangerRow(
              icon: Icons.delete_sweep_outlined,
              label: 'Reset everything',
              description: 'Bag, wishlist, orders, cards and history',
              destructive: true,
              onConfirm: () {
                ref.read(cartProvider.notifier).clear();
                ref.read(favoritesProvider.notifier).clear();
                ref.read(ordersProvider.notifier).clear();
                ref.read(searchHistoryProvider.notifier).clear();
                ref.read(recentlyViewedProvider.notifier).clear();
                ref.read(appliedPromoProvider.notifier).clear();
                ref.read(paymentCardsProvider.notifier).clear();
              },
            ),
          ],
        ),

        const SizedBox(height: 28),
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
                'imagery is loaded and cached from a public CDN. No real '
                'payment is ever taken.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Version 0.10.0 · prerelease',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!twoPane) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: master,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: TwoPane(
        list: master,
        detail: _pane == null
            ? null
            : DetailPaneSurface(
                child: KeyedSubtree(
                  key: ValueKey<SettingsPane>(_pane!),
                  child: _paneBody(_pane!),
                ),
              ),
        placeholder: const TwoPanePlaceholder(
          icon: Icons.tune_rounded,
          message: 'Choose a section to open it here.',
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({
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
  Widget build(BuildContext context) => SettingsRow(
    icon: icon,
    title: label,
    subtitle: description,
    destructive: destructive,
    trailing: const SizedBox.shrink(),
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
