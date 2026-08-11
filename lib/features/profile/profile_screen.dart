import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../state/addresses_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/favorites_provider.dart';
import '../../state/orders_provider.dart';
import '../checkout/widgets/address_sheet.dart';
import 'widgets/edit_name_sheet.dart';
import '../../state/profile_provider.dart';
import '../../state/auth_provider.dart';
import '../../data/models/account.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final int orderCount = ref.watch(ordersProvider).length;
    final int savedCount = ref.watch(favoritesProvider).length;
    final int bagCount = ref.watch(cartCountProvider);
    final int addressCount = ref.watch(addressesProvider).length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: <Widget>[
            Text('Profile', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 22),
            const _ProfileHeader(),
            const SizedBox(height: 14),
            const _AccountCard(),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatTile(
                    label: 'Orders',
                    value: '$orderCount',
                    icon: Icons.receipt_long_rounded,
                    onTap: () => context.push(Routes.orders),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Saved',
                    value: '$savedCount',
                    icon: Icons.favorite_rounded,
                    onTap: () => context.go(Routes.favorites),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'In bag',
                    value: '$bagCount',
                    icon: Icons.shopping_bag_rounded,
                    onTap: () => context.go(Routes.cart),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionCard(
              children: <Widget>[
                _Tile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Your orders',
                  subtitle: orderCount == 0
                      ? 'No orders yet'
                      : '$orderCount placed',
                  onTap: () => context.push(Routes.orders),
                ),
                _Tile(
                  icon: Icons.location_on_outlined,
                  title: 'Addresses',
                  subtitle: '$addressCount saved',
                  onTap: () => showAddressSheet(context),
                ),
                _Tile(
                  icon: Icons.credit_card_outlined,
                  title: 'Payment methods',
                  subtitle: 'Demo cards only',
                  onTap: () => _snack(
                    context,
                    'This build ships with demo cards — no real payments.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              children: <Widget>[
                _Tile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Appearance and data',
                  onTap: () => context.push(Routes.settings),
                ),
                _Tile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help centre',
                  subtitle: 'FAQs and contact',
                  onTap: () => _snack(context, 'Help centre coming soon.'),
                ),
                _Tile(
                  icon: Icons.code_rounded,
                  title: 'Source on GitHub',
                  subtitle: 'vladimirfiffie/ecommerce-app',
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://github.com/vladimirfiffie/ecommerce-app',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Center(
              child: Text(
                'Nova · prerelease build',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String stored = ref.watch(displayNameProvider);
    final String name = stored.isEmpty ? 'Add your name' : stored;

    return InkWell(
      onTap: () => showEditNameSheet(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 15,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Nova member',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 21, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.titleLarge),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: children),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

/// Signed-in account summary, or a prompt to sign in / create one.
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your bag, wishlist and orders stay on this device.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (yes ?? false) await ref.read(authProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Account? account = ref.watch(authProvider).account;

    if (account == null) {
      return Container(
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
            Text(
              'You’re browsing as a guest',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Everything works without an account — signing in just keeps '
              'your details together.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push(Routes.signIn),
                    child: const Text('Sign in'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(Routes.signUp),
                    child: const Text('Sign up'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.verified_user_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Signed in', style: theme.textTheme.titleSmall),
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _confirmSignOut(context, ref),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
