import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product.dart';
import 'app_providers.dart';

/// Lowercased haystacks, one per product, rebuilt only when the catalogue
/// changes.
///
/// [Product.searchIndex] concatenates and lowercases on every call, so
/// filtering straight off it re-derived ~200 strings on every keystroke.
final Provider<Map<String, String>> searchHaystackProvider =
    Provider<Map<String, String>>((Ref ref) {
      final List<Product> products = ref.watch(catalogDataProvider).products;
      return <String, String>{
        for (final Product p in products) p.id: p.searchIndex,
      };
    });

/// Ranked search over the catalogue.
///
/// Two things this does that a plain `contains` didn't:
///
/// * **Every word has to match, but not as one run.** "tee linen" and
///   "blue shirt" now find "Blue Linen Tee"; a contiguous-substring match
///   found neither.
/// * **Results are ordered by how well they match** rather than by catalogue
///   position, so typing a product's name puts it first instead of behind
///   whatever happened to share a tag.
List<Product> searchProducts(
  List<Product> products,
  Map<String, String> haystacks,
  String query, {
  int limit = 24,
}) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) return const <Product>[];

  final List<String> terms = q.split(RegExp(r'\s+'))
    ..removeWhere((String t) => t.isEmpty);
  if (terms.isEmpty) return const <Product>[];

  final List<(Product, int)> scored = <(Product, int)>[];
  for (final Product p in products) {
    final String haystack = haystacks[p.id] ?? p.searchIndex;
    if (!terms.every(haystack.contains)) continue;
    scored.add((p, _score(p, q, terms)));
  }

  scored.sort(((Product, int) a, (Product, int) b) {
    final int byScore = b.$2.compareTo(a.$2);
    // Rating breaks ties so equally-good matches lead with the better
    // product rather than whichever the API listed first.
    return byScore != 0 ? byScore : b.$1.rating.compareTo(a.$1.rating);
  });

  return <Product>[for (final (Product p, int _) in scored.take(limit)) p];
}

/// Higher is a better match. The bands are wide apart so a name hit always
/// outranks a tag hit regardless of the smaller bonuses.
int _score(Product p, String query, List<String> terms) {
  final String name = p.name.toLowerCase();
  int score = 0;

  if (name == query) {
    score += 1000;
  } else if (name.startsWith(query)) {
    score += 600;
  } else if (name.contains(query)) {
    score += 400;
  }

  // Each term found in the name counts, so a multi-word query that lands
  // entirely in the title beats one scattered across brand and tags.
  for (final String term in terms) {
    if (name.contains(term)) score += 60;
  }

  if (p.brand.toLowerCase().contains(query)) score += 120;
  if (p.subcategory.toLowerCase().contains(query)) score += 80;
  for (final String tag in p.tags) {
    if (tag.toLowerCase().contains(query)) {
      score += 40;
      break;
    }
  }

  // Nudge things you can actually buy above sold-out ones.
  if (p.stock > 0) score += 10;
  return score;
}
