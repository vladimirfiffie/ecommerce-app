import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/auth_provider.dart';

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
import '../../features/profile/security_settings_screen.dart';
import '../../features/profile/notification_settings_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/brand/brand_screen.dart';
import '../../features/profile/payment_methods_screen.dart';
import '../../features/profile/addresses_screen.dart';
import '../../features/orders/return_request_screen.dart';
import '../../features/orders/invoice_screen.dart';

/// Route paths, referenced by name everywhere else.
abstract final class Routes {
  static const String home = '/';
  static const String catalog = '/shop';
  static const String favorites = '/favorites';
  static const String cart = '/cart';
  static const String profile = '/profile';

  static const String search = '/search';
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String settings = '/settings';
  static const String haptics = '/settings/haptics';
  static const String security = '/settings/security';
  static const String notifications = '/settings/notifications';
  static const String addresses = '/settings/addresses';
  static const String payments = '/settings/payments';
  static const String orders = '/orders';

  static String product(String id) => '/product/$id';

  /// Brand is free text, so it has to be escaped into the path.
  static String brand(String name) => '/brand/${Uri.encodeComponent(name)}';

  static String order(String id) => '/orders/$id';
  static String invoice(String id) => '/orders/$id/receipt';
  static String returnRequest(String id) => '/orders/$id/return';
  static const String checkout = '/checkout';
  static String confirmation(String id) => '/confirmation/$id';
}

/// Custom scheme used by shared links.
const String kDeepLinkScheme = 'nova';

/// Web host that mirrors the app's routes, for https App Links.
const String kDeepLinkHost = 'nova.example.com';

/// A shareable link to a product.
String deepLinkForProduct(String productId) =>
    'https://$kDeepLinkHost/product/$productId';

/// Rewrites a custom-scheme link into an in-app route.
///
/// `nova://product/abc` parses with host `product` and path `/abc`, so the
/// path alone never matches a route — the host has to be folded back in.
/// https links already arrive with the full path and are left alone.
String? normalizeDeepLink(Uri uri) {
  if (uri.scheme != kDeepLinkScheme) return null;
  if (uri.host.isEmpty) return null;
  final String path = '/${uri.host}${uri.path}';
  return uri.hasQuery ? '$path?${uri.query}' : path;
}

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// The root navigator, for showing app-level sheets outside a widget tree.
GlobalKey<NavigatorState> get rootNavigatorKey => _rootKey;

/// True for the two routes that are reachable before the welcome gate is
/// cleared. Everything else redirects to [Routes.signIn].
bool _isAuthRoute(String location) =>
    location == Routes.signIn || location == Routes.signUp;

GoRouter createRouter(Ref ref) {
  // go_router only re-runs `redirect` when something tells it to, so the gate
  // has to be bridged into a Listenable. Without this, signing out leaves you
  // sitting on a screen you're no longer allowed to see.
  final ValueNotifier<bool> pastGate = ValueNotifier<bool>(
    ref.read(pastAuthGateProvider),
  );
  ref.listen<bool>(pastAuthGateProvider, (bool? _, bool next) {
    pastGate.value = next;
  });
  ref.onDispose(pastGate.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    refreshListenable: pastGate,
    redirect: (BuildContext context, GoRouterState state) {
      final String? rewritten = normalizeDeepLink(state.uri);
      // Returning the same location would loop.
      if (rewritten != null && rewritten != state.matchedLocation) {
        return rewritten;
      }

      // The shop opens on sign in / sign up. Guests get in by saying so.
      if (!pastGate.value && !_isAuthRoute(state.matchedLocation)) {
        return Routes.signIn;
      }
      return null;
    },
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
        // go_router hands back an already-decoded parameter, so the name is
        // used as-is — decoding again would mangle any brand with a % in it.
        path: '/brand/:name',
        parentNavigatorKey: _rootKey,
        builder: (BuildContext context, GoRouterState state) =>
            BrandScreen(brand: state.pathParameters['name']!),
      ),
      GoRoute(
        path: Routes.search,
        parentNavigatorKey: _rootKey,
        builder: (BuildContext context, GoRouterState state) =>
            const SearchScreen(),
      ),
      GoRoute(
        path: Routes.signIn,
        parentNavigatorKey: _rootKey,
        builder: (BuildContext context, GoRouterState state) =>
            const AuthScreen(),
      ),
      GoRoute(
        path: Routes.signUp,
        parentNavigatorKey: _rootKey,
        builder: (BuildContext context, GoRouterState state) =>
            const AuthScreen(startOnSignUp: true),
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
          GoRoute(
            path: 'security',
            parentNavigatorKey: _rootKey,
            builder: (BuildContext context, GoRouterState state) =>
                const SecuritySettingsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            parentNavigatorKey: _rootKey,
            builder: (BuildContext context, GoRouterState state) =>
                const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'addresses',
            parentNavigatorKey: _rootKey,
            builder: (BuildContext context, GoRouterState state) =>
                const AddressesScreen(),
          ),
          GoRoute(
            path: 'payments',
            parentNavigatorKey: _rootKey,
            builder: (BuildContext context, GoRouterState state) =>
                const PaymentMethodsScreen(),
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
            routes: <RouteBase>[
              GoRoute(
                path: 'receipt',
                parentNavigatorKey: _rootKey,
                builder: (BuildContext context, GoRouterState state) =>
                    InvoiceScreen(orderId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'return',
                parentNavigatorKey: _rootKey,
                builder: (BuildContext context, GoRouterState state) =>
                    ReturnRequestScreen(orderId: state.pathParameters['id']!),
              ),
            ],
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
}
