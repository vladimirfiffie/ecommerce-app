import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/cart_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/checkout/order_confirmation_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/haptics_settings_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/product/product_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shell/home_shell.dart';

/// Route paths, referenced by name everywhere else.
abstract final class Routes {
  static const String home = '/';
  static const String catalog = '/shop';
  static const String favorites = '/favorites';
  static const String cart = '/cart';
  static const String profile = '/profile';

  static const String search = '/search';
  static const String settings = '/settings';
  static const String haptics = '/settings/haptics';
  static const String orders = '/orders';

  static String product(String id) => '/product/$id';
  static String order(String id) => '/orders/$id';
  static const String checkout = '/checkout';
  static String confirmation(String id) => '/confirmation/$id';
}

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createRouter() => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: Routes.home,
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder:
          (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell shell,
          ) => HomeShell(shell: shell),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: Routes.home,
              pageBuilder: (BuildContext c, GoRouterState s) =>
                  const NoTransitionPage<void>(child: HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: Routes.catalog,
              pageBuilder: (BuildContext c, GoRouterState s) =>
                  const NoTransitionPage<void>(child: CatalogScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: Routes.favorites,
              pageBuilder: (BuildContext c, GoRouterState s) =>
                  const NoTransitionPage<void>(child: FavoritesScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: Routes.cart,
              pageBuilder: (BuildContext c, GoRouterState s) =>
                  const NoTransitionPage<void>(child: CartScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: Routes.profile,
              pageBuilder: (BuildContext c, GoRouterState s) =>
                  const NoTransitionPage<void>(child: ProfileScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/product/:id',
      parentNavigatorKey: _rootKey,
      builder: (BuildContext context, GoRouterState state) =>
          ProductDetailScreen(productId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: Routes.search,
      parentNavigatorKey: _rootKey,
      builder: (BuildContext context, GoRouterState state) =>
          const SearchScreen(),
    ),
    GoRoute(
      path: Routes.settings,
      parentNavigatorKey: _rootKey,
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'haptics',
          parentNavigatorKey: _rootKey,
          builder: (BuildContext context, GoRouterState state) =>
              const HapticsSettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: Routes.orders,
      parentNavigatorKey: _rootKey,
      builder: (BuildContext context, GoRouterState state) =>
          const OrdersScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: ':id',
          parentNavigatorKey: _rootKey,
          builder: (BuildContext context, GoRouterState state) =>
              OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: Routes.checkout,
      parentNavigatorKey: _rootKey,
      builder: (BuildContext context, GoRouterState state) =>
          const CheckoutScreen(),
    ),
    GoRoute(
      path: '/confirmation/:id',
      parentNavigatorKey: _rootKey,
      builder: (BuildContext context, GoRouterState state) =>
          OrderConfirmationScreen(orderId: state.pathParameters['id']!),
    ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.explore_off_rounded, size: 56),
            const SizedBox(height: 16),
            Text(
              'We couldn’t find that page',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Back to shop'),
            ),
          ],
        ),
      ),
    ),
  ),
);
