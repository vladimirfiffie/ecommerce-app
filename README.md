# Nova

A Material 3 storefront built entirely in Flutter — no web views, no platform UI,
just Flutter widgets and pub plugins.

> **Prerelease.** This is a demo/test build. Checkout is simulated: no real
> payment is taken and no payment data is collected or stored.

## What's in it

| Area | Details |
| --- | --- |
| **Welcome** | The app opens on sign in / create account, with a one-tap "browse as guest" that's remembered; signing out puts it back |
| **For you** | Live order progress with a stage tracker, delivery and return-window countdowns, refund ETA, price drops, back-in-stock, low stock on saved items, and how much more buys free delivery |
| **Home** | Auto-advancing promo carousel, category tiles, deals / new-arrivals / recently-viewed rails, popular grid, pull to refresh |
| **Shop** | The live catalog folded into 6 categories, category strip, grid/list toggle, filter & sort sheet (type, max price, min rating, on-sale, in-stock) |
| **Search** | Debounced live results, persisted recent searches, trending chips |
| **Product** | Swipeable gallery with pinch and double-tap zoom, size guide, variants, specifications table, Q&A, rating histogram, reviews, related rail, back-in-stock alerts |
| **Brand** | Tap the brand on any product for everything it sells, with product count, average rating, cheapest price and how many are on sale |
| **Bag** | Per-variant lines, swipe to delete with undo, promo codes, free-shipping progress, live order maths |
| **Checkout** | Shipping → payment → review stepper, validated address and card forms (Luhn, expiry, per-brand CVV, US ZIP), saved addresses and cards, three delivery speeds, gift wrap and message, order confirmation |
| **Orders** | Status tracker that advances over time, cancel before dispatch, partial returns with refund maths, shareable receipt, reorder at today's prices |
| **Saved** | Wishlist with bulk add-to-bag |
| **Reviews** | Verified buyers can write, edit and delete a review; it pins to the top of the list and folds into the rating average |
| **Profile** | Live "your orders" summary (newest order, its status, when it lands), editable name, light/dark/auto, 8 theme presets, AMOLED black, Material You, haptics, notifications, biometrics, data reset |

### Device integration

| | |
| --- | --- |
| **Haptics** | Master switch, three intensity levels, four mutable channels |
| **Notifications** | Permission flow, master switch and three categories; ordering posts a confirmation and schedules shipping/delivery notices |
| **Biometrics** | Opt-in verification before payment, with a capability report and a test prompt |
| **Screen readers** | A product card is one sentence, not six fragments; sale prices say which number is the old one; stars, steppers and gallery images are named. Flutter's tap-target, label and contrast guidelines are asserted in tests |
| **Large screens** | Navigation rail from 840dp, 2–6 column grids, two-pane product page and cart, unrestricted orientation |
| **AMOLED** | True-black dark surfaces that keep the brand palette and elevation tiers intact |
| **Deep links** | `nova://product/<id>` and https App Links resolve to in-app routes |
| **Personalization** | Time-aware greeting using your name, and 8 seed-colour presets that Material 3 expands into full light/dark schemes |
| **Accounts** | Local sign-up / sign-in with PBKDF2-hashed passwords. Optional — everything works as a guest |
| **Wallet** | Add/remove cards with Luhn validation and brand detection; only the last four digits are stored, never the CVV |
| **Settings** | Grouped by concern: account, shopping, appearance, feedback, security, data |

Everything the shopper does — bag, wishlist, orders, addresses, search history,
recently viewed, theme — persists across restarts via `shared_preferences`, and
so does the catalog those things resolve against, so the app opens without a
connection.

## Stack

- **Flutter 3.44** / Dart 3.12, Material 3
- **flutter_riverpod 3** — state, with a `sharedPreferencesProvider` seam that
  makes the whole persistence layer swappable in tests. Riverpod 3's automatic
  provider retry is switched off for the catalog on purpose: a provider being
  retried reports as loading, and a shop that can't be reached needs to say so
  rather than spin
- **go_router** — `StatefulShellRoute.indexedStack`, so each tab keeps its own
  navigation stack
- **http** — the live product feed
- **cached_network_image** + **shimmer** — image caching and loading skeletons
- **haptic_kit** — haptic feedback and tactile widgets
- **local_auth** — biometric verification before payment
- **flutter_local_notifications** + **timezone** — order-status notifications
- **flutter_animate** — entrance choreography
- **dynamic_color** — Material You palette on Android 12+
- **crypto** — PBKDF2-HMAC-SHA256 for local account passwords
- **flutter_localizations** + **intl** — `gen_l10n` against `lib/l10n/app_en.arb`
- **google_fonts**, **share_plus**, **url_launcher**

## Where the data comes from

Products come from [DummyJSON](https://dummyjson.com) — a free, keyless demo
API. One request fetches the lot; its 24 category slugs are folded into the six
storefront groups, and imagery is served from a public CDN and cached after
first load.

Nothing about that reaches the screens. Everything goes through
`ProductRepository`, so pointing this at a real backend means implementing one
interface and rebinding one provider:

```dart
// lib/state/app_providers.dart
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => CachedProductRepository(
    source: DummyJsonProductRepository(),   // ← swap for your own
    prefs: ref.watch(sharedPreferencesProvider),
  ),
);
```

`CachedProductRepository` keeps the last good catalog in
`shared_preferences`. That isn't only a speed trick: the bag, the wishlist and
pre-snapshot order lines are all stored as product ids and resolved against the
catalog on read, so a catalog held only in memory emptied every one of them on
a cold start with no signal — the bag read "Your bag is empty" while the tab
badge still showed the count. A snapshot is served while it's under six hours
old; after that a fetch is attempted and the snapshot is used only if that
fetch fails. Where a screen still can't resolve what it has, it now says the
shop is unreachable rather than claiming you own nothing.

Placed orders don't resolve against the catalog at all. Each line snapshots the
name, image and unit price at purchase, because an order is a record of
something that already happened: a repriced feed would otherwise rewrite the
total on a months-old receipt, and a delisted product would drop its line
entirely, leaving the printed lines short of the order's own stored subtotal.
Reorder is the one place that deliberately goes back to the live catalog — it's
a new purchase, so it uses today's price and stock.

## Layout

```
lib/
  core/         theme, router, formatters, enum copy lookups
  data/         models + repositories
  state/        Riverpod providers (cart, favorites, orders, filters, settings)
  features/     one folder per screen, with its own widgets/
  shared/       widgets reused across features
  l10n/         app_en.arb + generated/ (checked in; CI fails on drift)
```

## Language and region

Money and dates follow the device locale. Prices stay in US dollars because
that's the currency the feed quotes and converting them would need exchange
rates the app doesn't have — but `$1,299.50` in the US is `1.299,50 $` in
Germany and `2026年8月15日` is how Japan writes the date. `Intl.defaultLocale`
is set from whatever `MaterialApp` resolves, since `formatPrice` and friends
are plain functions with no context to ask.

Copy is looked up through `AppL10n`. The interesting part was the copy that
*couldn't* be: order statuses, return reasons, delivery names and auth errors
were `String` fields on their enums, which reads nicely but puts user-facing
words somewhere a `BuildContext` can never reach. Those enums now carry only
what's true in any language — ids, prices, timings, who pays return postage —
and the words moved to `lib/core/l10n/enum_labels.dart`.

Adding a language means dropping `app_<code>.arb` beside the English one and
running `flutter gen-l10n`; no screen changes. Screens outside the buy path
still hold their copy inline and want the same treatment.

## Running it

```bash
flutter pub get
flutter run                 # attached device
flutter run -d linux        # desktop
```

## Checks

```bash
flutter analyze --fatal-infos
flutter test                     # 411 tests
flutter test integration_test -d linux   # 4 end-to-end, real plugins
```

Coverage spans cart maths (variant merging, stock caps, promos, shipping
thresholds), catalog filtering and sorting, feed parsing and its error paths,
the offline snapshot and its staleness rules, order-line snapshots against a
repriced or shrunken feed, haptic gating and intensity scaling, breakpoint and
AMOLED behaviour, the biometric payment gate, notification gating, review
storage and rating maths, screen-reader labels and Flutter's own tap-target,
label and contrast guidelines, and locale-aware money and dates — plus widget
tests that drive the real purchase flow end to end: shop → product → bag →
checkout → confirmation.

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
git tag v0.10.0
git push origin v0.10.0
```

Grab `nova-v0.10.0-arm64-v8a.apk` for most modern phones, or the `universal` APK
if you're unsure. You'll need to allow installs from unknown sources.

> APKs are **signed with Android's debug key**. That's fine for sideloaded
> testing but not for distribution — add a real signing config in
> `android/app/build.gradle.kts` before shipping anywhere public.
>
> One consequence worth knowing: the runner generates a fresh debug key on
> every workflow run, so no two releases share a signature. Android refuses to
> install one over another and reports **"App not installed"**. Uninstall the
> old copy before installing a new one.
