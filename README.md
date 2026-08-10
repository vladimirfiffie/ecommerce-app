# Nova

A Material 3 storefront built entirely in Flutter — no web views, no platform UI,
just Flutter widgets and pub plugins.

> **Prerelease.** This is a demo/test build. Checkout is simulated: no real
> payment is taken and no payment data is collected or stored.

## What's in it

| Area | Details |
| --- | --- |
| **Home** | Auto-advancing promo carousel, category tiles, deals / new-arrivals / recently-viewed rails, popular grid, pull to refresh |
| **Shop** | 157 products across 6 categories, category strip, grid/list toggle, filter & sort sheet (type, max price, min rating, on-sale, in-stock) |
| **Search** | Debounced live results, persisted recent searches, trending chips |
| **Product** | Swipeable gallery with pinch-to-zoom, size and colour variants, quantity stepper, expandable description, rating histogram, reviews, related rail |
| **Bag** | Per-variant lines, swipe to delete with undo, promo codes, free-shipping progress, live order maths |
| **Checkout** | Shipping → payment → review stepper, saved addresses, order confirmation |
| **Orders** | History with a status tracker that advances over time, reorder |
| **Saved** | Wishlist with bulk add-to-bag |
| **Profile** | Light/dark/auto theme, Material You dynamic colour, data reset |

Everything the shopper does — bag, wishlist, orders, addresses, search history,
recently viewed, theme — persists across restarts via `shared_preferences`.

## Stack

- **Flutter 3.44** / Dart 3.12, Material 3
- **flutter_riverpod** — state, with a `sharedPreferencesProvider` seam that
  makes the whole persistence layer swappable in tests
- **go_router** — `StatefulShellRoute.indexedStack`, so each tab keeps its own
  navigation stack
- **cached_network_image** + **shimmer** — image caching and loading skeletons
- **flutter_animate** — entrance choreography
- **dynamic_color** — Material You palette on Android 12+
- **google_fonts**, **intl**, **share_plus**, **url_launcher**

## Where the data comes from

Products ship *inside* the app as `assets/data/catalog.json` and are loaded
through `ProductRepository`. Only imagery is remote (a public CDN), cached after
first load.

`MockProductRepository` is deliberately async with a small artificial latency so
the loading skeletons are exercised the way a real network repository would be.
Pointing this at a live backend means implementing one interface and rebinding
one provider — no screen code changes:

```dart
// lib/state/app_providers.dart
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => MockProductRepository(),   // ← swap for ApiProductRepository()
);
```

## Layout

```
lib/
  core/         theme, router, formatters
  data/         models + repositories
  state/        Riverpod providers (cart, favorites, orders, filters, settings)
  features/     one folder per screen, with its own widgets/
  shared/       widgets reused across features
assets/data/    the bundled catalog
```

## Running it

```bash
flutter pub get
flutter run                 # attached device
flutter run -d linux        # desktop
```

## Checks

```bash
flutter analyze --fatal-infos
flutter test                # 33 tests
```

Coverage spans cart maths (variant merging, stock caps, promos, shipping
thresholds), catalog filtering and sorting, catalog-asset integrity, and widget
tests that drive the real purchase flow end to end — shop → product → bag →
checkout → confirmation.

## Releases

Pushing a `v*` tag runs `.github/workflows/release.yml`, which analyzes, tests,
builds APKs (per-ABI plus universal) and publishes them as a GitHub
**prerelease**.

```bash
git tag v0.1.0
git push origin v0.1.0
```

Grab `nova-v0.1.0-arm64-v8a.apk` for most modern phones, or the `universal` APK
if you're unsure. You'll need to allow installs from unknown sources.

> APKs are **signed with Android's debug key**. That's fine for sideloaded
> testing but not for distribution — add a real signing config in
> `android/app/build.gradle.kts` before shipping anywhere public.
