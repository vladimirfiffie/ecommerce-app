import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../shared/widgets/catalog_unavailable.dart';
import '../../state/app_providers.dart';
import 'widgets/reviews_section.dart';

/// Every review for one product, with the filters that were under the fold.
///
/// The product page shows the first few and sends the rest here rather than
/// running a hundred reviews down a page that also has to sell something.
class AllReviewsScreen extends ConsumerWidget {
  const AllReviewsScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Catalog> catalog = ref.watch(catalogProvider);
    final Product? product = catalog.value?.byId(productId);

    return Scaffold(
      appBar: AppBar(title: Text(product?.name ?? 'Reviews')),
      body: switch ((catalog, product)) {
        (AsyncLoading<Catalog>(), _) => const Center(
          child: CircularProgressIndicator(),
        ),
        (_, null) => const CatalogUnavailable(
          title: 'We couldn’t load this product',
        ),
        (_, final Product p) => ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 40),
          // Not capped here: this is the page that exists to show them all.
          children: <Widget>[ReviewsSection(product: p, showAll: true)],
        ),
      },
    );
  }
}
