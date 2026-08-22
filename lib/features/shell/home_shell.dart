import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/router/app_router.dart';
import '../../state/cart_provider.dart';
import '../../state/favorites_provider.dart';
import '../../state/haptics_provider.dart';
import '../../state/settings_provider.dart';

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
    final bool labels = ref.watch(
      settingsProvider.select((AppSettings s) => s.navLabels),
    );

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
        label: 'Bag',
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
              labels: labels,
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
        // The label is still the semantic name of the tab either way, so
        // hiding it costs a screen reader nothing.
        labelBehavior: labels
            ? NavigationDestinationLabelBehavior.alwaysShow
            : NavigationDestinationLabelBehavior.alwaysHide,
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
    required this.labels,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Words alongside the icons. Off collapses the rail to its icon width,
  /// which the brand mark and the shortcuts below have to fit as well.
  final bool labels;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.none,
      extended: labels,
      minExtendedWidth: 200,
      backgroundColor: theme.colorScheme.surfaceContainer,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            if (labels) ...<Widget>[
              const SizedBox(width: 10),
              Text('Aster', style: theme.textTheme.titleLarge),
            ],
          ],
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: labels ? Alignment.bottomLeft : Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 16, left: labels ? 8 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _RailShortcut(
                  icon: Icons.receipt_long_outlined,
                  label: 'Orders',
                  labelled: labels,
                  onPressed: () => context.push(Routes.orders),
                ),
                _RailShortcut(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  labelled: labels,
                  onPressed: () => context.push(Routes.settings),
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

/// Orders and Settings under the rail, which lose their words with the tabs
/// above them but keep them as a tooltip.
class _RailShortcut extends StatelessWidget {
  const _RailShortcut({
    required this.icon,
    required this.label,
    required this.labelled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool labelled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!labelled) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        tooltip: label,
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
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
