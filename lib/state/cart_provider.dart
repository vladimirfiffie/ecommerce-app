import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/cart_entry.dart';
import '../data/models/delivery_option.dart';
import '../data/models/cart_item.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'app_providers.dart';

/// Storefront pricing rules, kept in one place so cart and checkout agree.
abstract final class Pricing {
  static const double freeShippingThreshold = 75;

  /// Kept for reference; the actual charge now comes from the chosen
  /// [DeliveryOption], whose standard rate matches this.
  static const double flatShipping = 6.95;
  static const double taxRate = 0.08;
}

/// The delivery method checkout will use. Persisted so it survives a restart.
class DeliveryOptionNotifier extends Notifier<DeliveryOption> {
  static const String _key = 'checkout.deliveryOption';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  DeliveryOption build() => DeliveryOption.byId(_prefs.getString(_key));

  Future<void> select(DeliveryOption option) async {
    state = option;
    await _prefs.setString(_key, option.id);
  }
}

/// Gift wrapping and an optional message, chosen at checkout.
@immutable
class GiftOptions {
  const GiftOptions({this.wrapped = false, this.message = ''});

  /// Flat fee added to the order when wrapping is chosen.
  static const double wrapFee = 4.5;

  final bool wrapped;
  final String message;

  bool get isGift => wrapped || message.trim().isNotEmpty;

  GiftOptions copyWith({bool? wrapped, String? message}) => GiftOptions(
    wrapped: wrapped ?? this.wrapped,
    message: message ?? this.message,
  );
}

/// Not persisted: a gift choice belongs to the order being placed, and
/// silently re-applying it to the next one would be a nasty surprise.
class GiftOptionsNotifier extends Notifier<GiftOptions> {
  @override
  GiftOptions build() => const GiftOptions();

  void setWrapped(bool value) => state = state.copyWith(wrapped: value);

  void setMessage(String value) => state = state.copyWith(message: value);

  void reset() => state = const GiftOptions();
}

final NotifierProvider<GiftOptionsNotifier, GiftOptions> giftOptionsProvider =
    NotifierProvider<GiftOptionsNotifier, GiftOptions>(GiftOptionsNotifier.new);

final NotifierProvider<DeliveryOptionNotifier, DeliveryOption>
deliveryOptionProvider =
    NotifierProvider<DeliveryOptionNotifier, DeliveryOption>(
      DeliveryOptionNotifier.new,
    );

/// A promo code the shopper can apply at checkout.
@immutable
class Promo {
  const Promo({
    required this.code,
    required this.description,
    this.percentOff = 0,
    this.freeShipping = false,
    this.minSubtotal = 0,
  });

  final String code;
  final String description;
  final double percentOff;
  final bool freeShipping;
  final double minSubtotal;
}

const List<Promo> kPromos = <Promo>[
  Promo(code: 'NOVA10', description: '10% off your order', percentOff: 0.10),
  Promo(
    code: 'WELCOME20',
    description: '20% off orders over \$100',
    percentOff: 0.20,
    minSubtotal: 100,
  ),
  Promo(
    code: 'FREESHIP',
    description: 'Free standard shipping',
    freeShipping: true,
  ),
];

/// The persisted cart. Lines are keyed by product + variant.
class CartNotifier extends Notifier<List<CartEntry>> {
  static const String _key = 'cart.entries';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<CartEntry> build() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <CartEntry>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return <CartEntry>[
        for (final Object? e in decoded)
          CartEntry.fromJson(e! as Map<String, dynamic>),
      ];
    } on FormatException {
      return const <CartEntry>[];
    }
  }

  Future<void> _persist(List<CartEntry> next) async {
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(next.map((CartEntry e) => e.toJson()).toList()),
    );
  }

  /// Adds [quantity] of a variant, merging into an existing line if present.
  Future<void> add(
    Product product, {
    String? size,
    ProductColor? color,
    int quantity = 1,
  }) async {
    final CartEntry incoming = CartEntry(
      productId: product.id,
      quantity: quantity,
      size: size,
      colorName: color?.name,
    );
    final List<CartEntry> next = <CartEntry>[...state];
    final int index = next.indexWhere(
      (CartEntry e) => e.lineId == incoming.lineId,
    );
    if (index >= 0) {
      final int merged = (next[index].quantity + quantity).clamp(
        1,
        product.stock,
      );
      next[index] = next[index].copyWith(quantity: merged);
    } else {
      next.add(incoming);
    }
    await _persist(next);
  }

  Future<void> setQuantity(String lineId, int quantity) async {
    if (quantity <= 0) return remove(lineId);
    final List<CartEntry> next = <CartEntry>[
      for (final CartEntry e in state)
        if (e.lineId == lineId) e.copyWith(quantity: quantity) else e,
    ];
    await _persist(next);
  }

  Future<void> increment(String lineId) async {
    final CartEntry? entry = _find(lineId);
    if (entry == null) return;
    final Product? product = ref
        .read(catalogDataProvider)
        .byId(entry.productId);
    final int max = product?.stock ?? 99;
    if (entry.quantity >= max) return;
    await setQuantity(lineId, entry.quantity + 1);
  }

  Future<void> decrement(String lineId) async {
    final CartEntry? entry = _find(lineId);
    if (entry == null) return;
    await setQuantity(lineId, entry.quantity - 1);
  }

  Future<void> remove(String lineId) async {
    await _persist(<CartEntry>[
      for (final CartEntry e in state)
        if (e.lineId != lineId) e,
    ]);
  }

  /// Puts a removed line back at [index] — used by the undo snackbar.
  Future<void> restore(CartEntry entry, int index) async {
    final List<CartEntry> next = <CartEntry>[...state];
    next.insert(index.clamp(0, next.length), entry);
    await _persist(next);
  }

  Future<void> clear() async {
    state = const <CartEntry>[];
    await _prefs.remove(_key);
  }

  CartEntry? _find(String lineId) {
    for (final CartEntry e in state) {
      if (e.lineId == lineId) return e;
    }
    return null;
  }
}

final NotifierProvider<CartNotifier, List<CartEntry>> cartProvider =
    NotifierProvider<CartNotifier, List<CartEntry>>(CartNotifier.new);

/// Cart lines joined with live product data. Entries whose product is no longer
/// in the catalog are dropped.
final Provider<List<CartItem>> cartItemsProvider = Provider<List<CartItem>>((
  Ref ref,
) {
  final List<CartEntry> entries = ref.watch(cartProvider);
  final Catalog catalog = ref.watch(catalogDataProvider);
  return <CartItem>[
    for (final CartEntry e in entries)
      if (catalog.byId(e.productId) case final Product p)
        CartItem(entry: e, product: p),
  ];
});

/// Total units in the cart — drives the nav bar badge.
final Provider<int> cartCountProvider = Provider<int>(
  (Ref ref) => ref
      .watch(cartProvider)
      .fold(0, (int sum, CartEntry e) => sum + e.quantity),
);

/// The promo code currently applied, if any.
class AppliedPromoNotifier extends Notifier<Promo?> {
  @override
  Promo? build() => null;

  /// Returns null on success, or a human-readable reason for rejection.
  String? apply(String code, double subtotal) {
    final String normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return 'Enter a code';
    Promo? match;
    for (final Promo p in kPromos) {
      if (p.code == normalized) {
        match = p;
        break;
      }
    }
    if (match == null) return 'That code isn’t valid';
    if (subtotal < match.minSubtotal) {
      return 'Spend \$${match.minSubtotal.toStringAsFixed(0)}+ to use this code';
    }
    state = match;
    return null;
  }

  void clear() => state = null;
}

final NotifierProvider<AppliedPromoNotifier, Promo?> appliedPromoProvider =
    NotifierProvider<AppliedPromoNotifier, Promo?>(AppliedPromoNotifier.new);

/// Order maths for the cart and checkout summaries.
@immutable
class CartSummary {
  const CartSummary({
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.tax,
    required this.total,
    required this.amountToFreeShipping,
    this.delivery = DeliveryOption.standard,
    this.giftFee = 0,
  });

  final int itemCount;
  final double subtotal;
  final double discount;
  final double shipping;
  final double tax;
  final double total;

  /// How much more to spend before shipping is free; zero once it is.
  final double amountToFreeShipping;

  final DeliveryOption delivery;

  /// Gift wrapping charge, zero when not gifting.
  final double giftFee;

  DateTime get estimatedArrival => delivery.estimatedArrival(DateTime.now());

  bool get isEmpty => itemCount == 0;
  bool get hasFreeShipping => shipping == 0 && subtotal > 0;
}

final Provider<CartSummary> cartSummaryProvider = Provider<CartSummary>((
  Ref ref,
) {
  final List<CartItem> items = ref.watch(cartItemsProvider);
  final Promo? promo = ref.watch(appliedPromoProvider);
  final DeliveryOption delivery = ref.watch(deliveryOptionProvider);
  final GiftOptions gift = ref.watch(giftOptionsProvider);

  final double subtotal = items.fold(
    0,
    (double sum, CartItem i) => sum + i.lineTotal,
  );
  final int count = items.fold(0, (int sum, CartItem i) => sum + i.quantity);

  final double discount = promo == null ? 0 : subtotal * promo.percentOff;
  final double discounted = subtotal - discount;

  // Free-shipping perks apply to standard delivery only: expediting costs
  // real money, so neither the threshold nor a FREESHIP code waives it.
  double shipping = 0;
  if (subtotal > 0) {
    final bool waived =
        delivery.freeOverThreshold &&
        (discounted >= Pricing.freeShippingThreshold ||
            (promo?.freeShipping ?? false));
    shipping = waived ? 0 : delivery.price;
  }

  final double giftFee = gift.wrapped ? GiftOptions.wrapFee : 0;
  final double tax = (discounted + giftFee) * Pricing.taxRate;

  return CartSummary(
    itemCount: count,
    subtotal: subtotal,
    discount: discount,
    shipping: shipping,
    tax: tax,
    total: discounted + shipping + giftFee + tax,
    delivery: delivery,
    giftFee: giftFee,
    amountToFreeShipping: subtotal == 0
        ? 0
        : (Pricing.freeShippingThreshold - discounted).clamp(
            0,
            Pricing.freeShippingThreshold,
          ),
  );
});
