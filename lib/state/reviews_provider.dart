import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/cart_entry.dart';
import '../data/models/order.dart';
import '../data/models/product.dart';
import '../data/models/review.dart';
import 'app_providers.dart';
import 'orders_provider.dart';

/// A review the shopper wrote, stored on this device.
@immutable
class UserReview {
  const UserReview({
    required this.productId,
    required this.rating,
    required this.body,
    required this.writtenAt,
    this.title = '',
  });

  factory UserReview.fromJson(Map<String, dynamic> json) => UserReview(
    productId: json['productId'] as String,
    rating: (json['rating'] as num).toDouble(),
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    writtenAt: DateTime.parse(json['writtenAt'] as String),
  );

  final String productId;
  final double rating;
  final String title;
  final String body;
  final DateTime writtenAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'productId': productId,
    'rating': rating,
    'title': title,
    'body': body,
    'writtenAt': writtenAt.toIso8601String(),
  };

  /// Rendered into the same [Review] shape the bundled catalog uses, so the
  /// product page can show one list.
  Review toReview() => Review(
    author: 'You',
    rating: rating,
    body: title.isEmpty ? body : '$title\n$body',
    daysAgo: DateTime.now().difference(writtenAt).inDays,
  );
}

/// Reviews written on this device, newest first.
class UserReviewsNotifier extends Notifier<List<UserReview>> {
  static const String _key = 'reviews.mine';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<UserReview> build() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <UserReview>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return <UserReview>[
        for (final Object? r in decoded)
          UserReview.fromJson(r! as Map<String, dynamic>),
      ];
    } on FormatException {
      return const <UserReview>[];
    }
  }

  /// Adds or replaces this device's review for a product — one per product,
  /// like every real storefront.
  Future<void> save(UserReview review) async {
    final List<UserReview> next = <UserReview>[
      review,
      ...state.where((UserReview r) => r.productId != review.productId),
    ];
    await _persist(next);
  }

  Future<void> delete(String productId) async {
    await _persist(<UserReview>[
      for (final UserReview r in state)
        if (r.productId != productId) r,
    ]);
  }

  Future<void> clear() async {
    state = const <UserReview>[];
    await _prefs.remove(_key);
  }

  Future<void> _persist(List<UserReview> next) async {
    state = next;
    await _prefs.setString(
      _key,
      jsonEncode(next.map((UserReview r) => r.toJson()).toList()),
    );
  }
}

final NotifierProvider<UserReviewsNotifier, List<UserReview>>
userReviewsProvider = NotifierProvider<UserReviewsNotifier, List<UserReview>>(
  UserReviewsNotifier.new,
);

/// This device's review of a product, if there is one.
final ProviderFamily<UserReview?, String> myReviewProvider =
    Provider.family<UserReview?, String>((Ref ref, String productId) {
      for (final UserReview r in ref.watch(userReviewsProvider)) {
        if (r.productId == productId) return r;
      }
      return null;
    });

/// Only shoppers who bought the item may review it — the same rule real
/// storefronts use to keep review sections honest.
final ProviderFamily<bool, String> canReviewProvider =
    Provider.family<bool, String>(
      (Ref ref, String productId) => ref
          .watch(ordersProvider)
          .any(
            (Order order) => order.entries.any(
              (CartEntry entry) => entry.productId == productId,
            ),
          ),
    );

/// The catalog's reviews with this device's own review pinned to the top.
final ProviderFamily<List<Review>, Product> productReviewsProvider =
    Provider.family<List<Review>, Product>((Ref ref, Product product) {
      final UserReview? mine = ref.watch(myReviewProvider(product.id));
      return <Review>[if (mine != null) mine.toReview(), ...product.reviews];
    });

/// Average rating including this device's review, so the summary agrees with
/// the list beneath it.
final ProviderFamily<({double rating, int count}), Product>
productRatingProvider = Provider.family<({double rating, int count}), Product>((
  Ref ref,
  Product product,
) {
  final UserReview? mine = ref.watch(myReviewProvider(product.id));
  if (mine == null) {
    return (rating: product.rating, count: product.reviewCount);
  }
  // Fold one new score into the published average.
  final int count = product.reviewCount + 1;
  final double total = product.rating * product.reviewCount + mine.rating;
  return (rating: total / count, count: count);
});
