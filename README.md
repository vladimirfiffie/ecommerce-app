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
| **Product** | Swipeable gallery with pinch and double-tap zoom, size guide, variants, Q&A, rating histogram, reviews, related rail, back-in-stock alerts |
| **Bag** | Per-variant lines, swipe to delete with undo, promo codes, free-shipping progress, live order maths |
| **Checkout** | Shipping → payment → review stepper, saved addresses and cards, three delivery speeds, gift wrap and message, order confirmation |
| **Orders** | Status tracker that advances over time, cancel before dispatch, partial returns with refund maths, shareable receipt, reorder |
| **Saved** | Wishlist with bulk add-to-bag |
| **Reviews** | Verified buyers can write, edit and delete a review; it pins to the top of the list and folds into the rating average |
| **Profile** | Editable name, light/dark/auto, 8 theme presets, AMOLED black, Material You, haptics, notifications, biometrics, data reset |

### Device integration

| | |
| --- | --- |
| **Haptics** | Master switch, three intensity levels, four mutable channels, live capability report and a playground covering every `haptic_kit` primitive and widget |
| **Notifications** | Permission flow, master switch and three categories; ordering posts a confirmation and schedules shipping/delivery notices |
| **Biometrics** | Opt-in verification before payment, with a capability report and a test prompt |
| **Large screens** | Navigation rail from 840dp, 2–6 column grids, two-pane product page and cart, unrestricted orientation |
| **AMOLED** | True-black dark surfaces that keep the brand palette and elevation tiers intact |
| **Deep links** | `nova://product/<id>` and https App Links resolve to in-app routes |
| **Personalization** | Time-aware greeting using your name, and 8 seed-colour presets that Material 3 expands into full light/dark schemes |
| **Accounts** | Local sign-up / sign-in with PBKDF2-hashed passwords. Optional — everything works as a guest |
| **Wallet** | Add/remove cards with Luhn validation and brand detection; only the last four digits are stored, never the CVV |
| **Settings** | Grouped by concern: account, shopping, appearance, feedback, security, data |

Everything the shopper does — bag, wishlist, orders, addresses, search history,
recently viewed, theme — persists across restarts via `shared_preferences`.

## Stack

- **Flutter 3.44** / Dart 3.12, Material 3
- **flutter_riverpod** — state, with a `sharedPreferencesProvider` seam that
  makes the whole persistence layer swappable in tests
- **go_router** — `StatefulShellRoute.indexedStack`, so each tab keeps its own
  navigation stack
- **cached_network_image** + **shimmer** — image caching and loading skeletons
- **haptic_kit** — haptic feedback and tactile widgets
- **local_auth** — biometric verification before payment
- **flutter_local_notifications** + **timezone** — order-status notifications
- **flutter_animate** — entrance choreography
- **dynamic_color** — Material You palette on Android 12+
- **crypto** — PBKDF2-HMAC-SHA256 for local account passwords
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
flutter test                     # 207 tests
flutter test integration_test -d linux   # 4 end-to-end, real plugins
```

Coverage spans cart maths (variant merging, stock caps, promos, shipping
thresholds), catalog filtering and sorting, catalog-asset integrity, haptic
gating and intensity scaling, breakpoint and AMOLED behaviour, the biometric
payment gate, notification gating, review storage and rating maths — plus
widget tests that drive the real purchase flow end to end: shop → product →
bag → checkout → confirmation.

Three subsystems talk to plugins that only exist on Android and iOS. Each is
wrapped in a service that is platform-guarded and non-throwing, because
decorative feedback must never be able to break a checkout — a lesson learned
when an unregistered notification plugin raised a `LateInitializationError`
(an `Error`, not an `Exception`) and took order placement down in two tests.

## Releases

Pushing a `v*` tag runs `.github/workflows/release.yml`, which analyzes, tests,
builds APKs (per-ABI plus universal) and publishes them as a GitHub
**prerelease**.

```bash
git tag v0.4.1
git push origin v0.4.1
```

Grab `nova-v0.4.1-arm64-v8a.apk` for most modern phones, or the `universal` APK
if you're unsure. You'll need to allow installs from unknown sources.

> APKs are **signed with Android's debug key**. That's fine for sideloaded
> testing but not for distribution — add a real signing config in
> `android/app/build.gradle.kts` before shipping anywhere public.
