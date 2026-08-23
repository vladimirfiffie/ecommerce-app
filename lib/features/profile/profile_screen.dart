import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../state/orders_provider.dart';
import 'widgets/edit_name_sheet.dart';
import '../../state/profile_provider.dart';
import '../../state/auth_provider.dart';
import '../../data/models/account.dart';
import '../../shared/widgets/confirm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

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
            const SizedBox(height: 28),
            const _SectionCard(children: <Widget>[_OrdersTile()]),
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
                  icon: Icons.rate_review_outlined,
                  title: 'Your reviews',
                  subtitle: 'What you have said about what you bought',
                  onTap: () => context.push(Routes.myReviews),
                ),
                _Tile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help center',
                  subtitle: 'FAQs and contact',
                  onTap: () => context.push(Routes.help),
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
                'Aster · prerelease build',
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
                        'Aster member',
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AdaptiveCard(
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
    return AdaptiveListTile(
      // Material's row geometry — see SettingsRow for why.
      padding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

/// Orders entry point, showing where the newest order actually is.
///
/// A count alone ("3 placed") is the one thing nobody opens this screen to
/// find out. Status is derived from the clock, so this tracks it live rather
/// than freezing at whatever it said when the tab was opened.
class _OrdersTile extends ConsumerWidget {
  const _OrdersTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Order> orders = ref.watch(ordersProvider);
    ref.watch(orderClockProvider);

    return _Tile(
      icon: Icons.receipt_long_outlined,
      title: 'Your orders',
      subtitle: _subtitle(orders, AppL10n.of(context)),
      onTap: () => context.push(Routes.orders),
    );
  }

  String _subtitle(List<Order> orders, AppL10n l10n) {
    if (orders.isEmpty) return 'No orders yet';

    final Order latest = orders.first;
    final StringBuffer line = StringBuffer(
      '${latest.id} · ${latest.status.labelIn(l10n)}',
    );

    // An arrival date is only news while the parcel is still coming.
    if (latest.status == OrderStatus.processing ||
        latest.status == OrderStatus.shipped) {
      line.write(' · arriving ${formatDeliveryDate(latest.estimatedDelivery)}');
    } else if (latest.status == OrderStatus.delivered && latest.canReturn) {
      final int days = latest.returnDaysLeft;
      line.write(' · ${days}d left to return');
    }

    if (orders.length > 1) line.write('\n+${orders.length - 1} more');
    return line.toString();
  }
}

/// Signed-in account summary, or a prompt to sign in / create one.
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final bool yes = await confirmDestructive(
      context,
      title: 'Sign out?',
      message: 'Your bag, wishlist and orders stay on this device.',
      confirmLabel: 'Sign out',
    );
    if (yes) await ref.read(authProvider.notifier).signOut();
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
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
