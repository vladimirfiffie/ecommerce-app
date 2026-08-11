import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/price_text.dart';
import '../../state/app_providers.dart';
import '../../state/catalog_filter_provider.dart';
import '../product/product_detail_screen.dart';
import '../../core/layout/two_pane.dart';
import '../../shared/widgets/nova_refresh.dart';

/// Live search over the catalog with recent terms and trending suggestions.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  String _query = '';
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _query = ref.read(catalogFilterProvider).query;
    _controller.text = _query;
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Debounced so typing doesn't re-filter 150 products on every keystroke.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _query = value);
    });
  }

  /// Commits the term to the catalog filter and hands off to the Shop tab.
  void _submit(String term) {
    final String value = term.trim();
    if (value.isEmpty) return;
    ref.read(searchHistoryProvider.notifier).record(value);
    ref.read(catalogFilterProvider.notifier).setQuery(value);
    context.go(Routes.catalog);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Catalog catalog = ref.watch(catalogDataProvider);
    final String q = _query.trim().toLowerCase();

    final List<Product> matches = q.isEmpty
        ? const <Product>[]
        : catalog.products
              .where((Product p) => p.searchIndex.contains(q))
              .take(24)
              .toList();

    final bool twoPane = useTwoPane(context);
    final String? selected =
        twoPane && matches.any((Product p) => p.id == _selectedId)
        ? _selectedId
        : null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _submit,
          decoration: InputDecoration(
            hintText: 'Search products, brands…',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
      ),
      body: _maybeTwoPane(
        twoPane: twoPane,
        selected: selected,
        child: q.isEmpty
            ? _Suggestions(
                onPick: (String term) {
                  _controller.text = term;
                  setState(() => _query = term);
                },
                onSubmit: _submit,
              )
            : matches.isEmpty
            ? EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No results for “$_query”',
                message: 'Check the spelling, or try a broader term.',
              )
            : NovaRefresh(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: matches.length,
                  separatorBuilder: (BuildContext c, int i) =>
                      const Divider(height: 1, indent: 84),
                  itemBuilder: (BuildContext context, int index) {
                    final Product product = matches[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: SizedBox(
                        width: 52,
                        height: 52,
                        child: AppImage(
                          url: product.thumbnail,
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                      ),
                      title: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        '${product.brand}  ·  ${product.subcategory}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PriceText(product: product, compact: true),
                      selected: product.id == selected,
                      onTap: () {
                        ref
                            .read(searchHistoryProvider.notifier)
                            .record(product.name);
                        if (twoPane) {
                          setState(() => _selectedId = product.id);
                        } else {
                          context.push(Routes.product(product.id));
                        }
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  /// Results alone on a phone; results beside the chosen product on a tablet.
  Widget _maybeTwoPane({
    required bool twoPane,
    required String? selected,
    required Widget child,
  }) {
    if (!twoPane) return child;
    return TwoPane(
      list: child,
      detail: selected == null
          ? null
          : DetailPaneSurface(
              child: ProductDetailScreen(
                key: ValueKey<String>(selected),
                productId: selected,
                embedded: true,
              ),
            ),
      placeholder: const TwoPanePlaceholder(
        icon: Icons.search_rounded,
        message: 'Pick a result to see it here.',
      ),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.onPick, required this.onSubmit});

  final ValueChanged<String> onPick;
  final ValueChanged<String> onSubmit;

  static const List<String> _trending = <String>[
    'Sunglasses',
    'Laptops',
    'Fragrances',
    'Dresses',
    'Watches',
    'Kitchen',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<String> history = ref.watch(searchHistoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: <Widget>[
        if (history.isNotEmpty) ...<Widget>[
          Row(
            children: <Widget>[
              Text('Recent', style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    ref.read(searchHistoryProvider.notifier).clear(),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final String term in history)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded),
              title: Text(term),
              trailing: IconButton(
                icon: const Icon(Icons.north_west_rounded, size: 18),
                onPressed: () => onPick(term),
                tooltip: 'Fill in',
              ),
              onTap: () => onSubmit(term),
            ),
          const SizedBox(height: 24),
        ],
        Text('Trending', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String term in _trending)
              ActionChip(label: Text(term), onPressed: () => onPick(term)),
          ],
        ),
      ],
    );
  }
}
