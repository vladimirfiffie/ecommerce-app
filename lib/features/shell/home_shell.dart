import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/router/app_router.dart';
import '../../state/cart_provider.dart';
import '../../state/favorites_provider.dart';
import '../../state/haptics_provider.dart';

/// A single destination, rendered as either a bar item or a rail item.
class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int badgeCount;
}

/// Root scaffold hosting the five tabs.
///
/// Uses go_router's [StatefulNavigationShell] so each tab keeps its own
/// navigation stack and scroll position, and swaps between a bottom bar and a
/// side rail depending on how much width the window has.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _onTap(WidgetRef ref, int index) {
    unawaited(ref.read(hapticsProvider).selection());
    // Tapping the active tab pops it back to its root.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int cartCount = ref.watch(cartCountProvider);
    final int favoriteCount = ref.watch(favoritesProvider).length;
    final WindowSize size = Breakpoints.of(context);

    final List<_Destination> destinations = <_Destination>[
      const _Destination(
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
      ),
      const _Destination(
        label: 'Shop',
        icon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view_rounded,
      ),
      _Destination(
        label: 'Saved',
        icon: Icons.favorite_border_rounded,
        selectedIcon: Icons.favorite_rounded,
        badgeCount: favoriteCount,
      ),
      _Destination(
        label: 'Cart',
        icon: Icons.shopping_bag_outlined,
        selectedIcon: Icons.shopping_bag_rounded,
        badgeCount: cartCount,
      ),
      const _Destination(
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];

    if (size.isWide) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            _Rail(
              destinations: destinations,
              selectedIndex: shell.currentIndex,
              onSelected: (int i) => _onTap(ref, i),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (int i) => _onTap(ref, i),
        destinations: <Widget>[
          for (final _Destination d in destinations)
            NavigationDestination(
              icon: _CountBadge(count: d.badgeCount, child: Icon(d.icon)),
              selectedIcon: _CountBadge(
                count: d.badgeCount,
                child: Icon(d.selectedIcon),
              ),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

/// Extended rail for wide windows, with the brand mark and a shortcut to
/// orders — space the bottom bar never had.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.none,
      extended: true,
      minExtendedWidth: 200,
      backgroundColor: theme.colorScheme.surfaceContainer,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 24),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text('Nova', style: theme.textTheme.titleLarge),
          ],
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextButton.icon(
                  onPressed: () => context.push(Routes.orders),
                  icon: const Icon(Icons.receipt_long_outlined, size: 20),
                  label: const Text('Orders'),
                ),
                TextButton.icon(
                  onPressed: () => context.push(Routes.settings),
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  label: const Text('Settings'),
                ),
              ],
            ),
          ),
        ),
      ),
      destinations: <NavigationRailDestination>[
        for (final _Destination d in destinations)
          NavigationRailDestination(
            icon: _CountBadge(count: d.badgeCount, child: Icon(d.icon)),
            selectedIcon: _CountBadge(
              count: d.badgeCount,
              child: Icon(d.selectedIcon),
            ),
            label: Text(d.label),
          ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Badge.count(
      count: count,
      backgroundColor: Theme.of(context).colorScheme.error,
      textColor: Theme.of(context).colorScheme.onError,
      child: child,
    );
  }
}
