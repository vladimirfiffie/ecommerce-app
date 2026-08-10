import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/cart_provider.dart';
import '../../state/favorites_provider.dart';

/// Bottom-nav scaffold hosting the five root tabs.
///
/// Uses go_router's [StatefulNavigationShell] so each tab keeps its own
/// navigation stack and scroll position.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    // Tapping the active tab pops it back to its root.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int cartCount = ref.watch(cartCountProvider);
    final int favoriteCount = ref.watch(favoritesProvider).length;

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: <Widget>[
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: _CountBadge(
              count: favoriteCount,
              child: const Icon(Icons.favorite_border_rounded),
            ),
            selectedIcon: _CountBadge(
              count: favoriteCount,
              child: const Icon(Icons.favorite_rounded),
            ),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: _CountBadge(
              count: cartCount,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: _CountBadge(
              count: cartCount,
              child: const Icon(Icons.shopping_bag_rounded),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
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
