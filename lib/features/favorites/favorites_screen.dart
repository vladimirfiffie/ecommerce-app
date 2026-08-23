import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../../shared/widgets/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../shared/widgets/catalog_unavailable.dart';
import '../../shared/widgets/empty_state.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/app_providers.dart';
import '../../state/cart_provider.dart';
import '../../state/wishlists_provider.dart';
import '../../data/models/wish_list.dart';
import '../../shared/widgets/confirm.dart';
import 'widgets/list_strip.dart';
import '../../shared/widgets/product_grid.dart';
import '../../core/layout/breakpoints.dart';
import '../product/product_detail_screen.dart';
import '../../core/layout/two_pane.dart';
import '../../shared/widgets/aster_refresh.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String? _selectedId;
  String _listId = WishList.defaultId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<WishList> lists = ref.watch(wishListsProvider);

    // A list the shopper just deleted leaves the tab pointing at nothing.
    final WishList list = lists.firstWhere(
      (WishList l) => l.id == _listId,
      orElse: () => lists.first,
    );
    final List<Product> products = ref.watch(wishListProductsProvider(list.id));
    final double gutter = Breakpoints.gutter(Breakpoints.of(context));

    // Saved items are ids resolved against the catalog, so "nothing saved" and
    // "couldn't look up what you saved" render identically unless asked apart.
    final AsyncValue<Catalog> catalog = ref.watch(catalogProvider);
    final bool unresolved = products.isEmpty && list.productIds.isNotEmpty;
    final bool twoPane = useTwoPane(context);
    final String? selected =
        twoPane && products.any((Product p) => p.id == _selectedId)
        ? _selectedId
        : null;

    final Widget master = SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text('Saved', style: theme.textTheme.headlineMedium),
                ),
                _ListMenu(
                  list: list,
                  onRename: () => _rename(list),
                  onDelete: () => _delete(list),
                  onEmpty: () => _empty(list),
                  onNew: _createList,
                ),
              ],
            ),
          ),
          ListStrip(
            lists: lists,
            selectedId: list.id,
            onSelect: (String id) => setState(() => _listId = id),
            onNew: _createList,
          ),
          if (products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${products.length} ${products.length == 1 ? 'item' : 'items'}',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addAll(context, ref, products),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: const Text('Add all'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: unresolved && catalog.isLoading
                ? const Center(child: CircularProgressIndicator())
                : unresolved
                ? CatalogUnavailable(
                    title: AppL10n.of(context).couldNotLoadSaves,
                  )
                : products.isEmpty
                ? EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: list.isDefault
                        ? 'Nothing saved yet'
                        : '${list.name} is empty',
                    message: list.isDefault
                        ? 'Tap the heart on anything you like and it’ll wait for you here.'
                        : 'Hold the heart on anything you like to put it in this list.',
                    actionLabel: 'Browse the shop',
                    onAction: () => context.go(Routes.catalog),
                  )
                : AsterRefresh(
                    child: ProductGrid(
                      products: products,
                      heroPrefix: 'saved',
                      key: ValueKey<String>(list.id),
                      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 32),
                      selectedId: selected,
                      onSelect: twoPane
                          ? (String id) => setState(() => _selectedId = id)
                          : null,
                    ),
                  ),
          ),
        ],
      ),
    );

    if (!twoPane) return Scaffold(body: master);

    return Scaffold(
      body: TwoPane(
        list: master,
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
          icon: Icons.favorite_border_rounded,
          message: 'Pick something you saved to see it here.',
        ),
      ),
    );
  }

  Future<void> _createList() async {
    final String? name = await _askForName(context, title: 'New list');
    if (name == null) return;
    final String? id = await ref.read(wishListsProvider.notifier).create(name);
    if (id != null && mounted) setState(() => _listId = id);
  }

  Future<void> _rename(WishList list) async {
    final String? name = await _askForName(
      context,
      title: 'Rename list',
      initial: list.name,
    );
    if (name == null) return;
    await ref.read(wishListsProvider.notifier).rename(list.id, name);
  }

  Future<void> _delete(WishList list) async {
    final bool yes = await confirmDestructive(
      context,
      title: 'Delete ${list.name}?',
      message: list.length == 0
          ? 'The list will be removed.'
          : 'The list and the ${list.length} '
                '${list.length == 1 ? 'item' : 'items'} in it will be '
                'removed. The products themselves stay in the shop.',
      confirmLabel: 'Delete',
    );
    if (!yes) return;
    await ref.read(wishListsProvider.notifier).delete(list.id);
    if (mounted) setState(() => _listId = WishList.defaultId);
  }

  Future<void> _empty(WishList list) async {
    final bool yes = await confirmDestructive(
      context,
      title: 'Empty ${list.name}?',
      message: 'Everything in this list will be unsaved.',
      confirmLabel: 'Empty',
    );
    if (yes) await ref.read(wishListsProvider.notifier).emptyList(list.id);
  }

  /// Only products with no variant choices can be bulk-added; anything needing
  /// a size or color is skipped so we never guess on the shopper's behalf.
  Future<void> _addAll(
    BuildContext context,
    WidgetRef ref,
    List<Product> products,
  ) async {
    int added = 0;
    int skipped = 0;
    for (final Product product in products) {
      if (!product.inStock) continue;
      if (product.sizes.isNotEmpty || product.colors.isNotEmpty) {
        skipped++;
        continue;
      }
      await ref.read(cartProvider.notifier).add(product);
      added++;
    }

    if (!context.mounted) return;
    final String message = switch ((added, skipped)) {
      (0, 0) => 'Nothing available to add',
      (0, _) => 'These need a size or color — open them to choose',
      (_, 0) => 'Added $added to your bag',
      _ => 'Added $added — $skipped need a size or color',
    };
    showMessage(context, message);
  }
}

/// Asks for a list name, returning null when the shopper backs out.
Future<String?> _askForName(
  BuildContext context, {
  required String title,
  String initial = '',
}) async {
  final TextEditingController controller = TextEditingController(text: initial);
  final String? name = await showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: AdaptiveTextField(
        controller: controller,
        autofocus: true,
        maxLength: WishList.maxNameLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (String value) => Navigator.of(context).pop(value),
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'Birthday ideas',
          counterText: '',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  final String? trimmed = name?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Rename, empty, delete — and a way to start another list.
class _ListMenu extends StatelessWidget {
  const _ListMenu({
    required this.list,
    required this.onRename,
    required this.onDelete,
    required this.onEmpty,
    required this.onNew,
  });

  final WishList list;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onEmpty;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) => AdaptivePopupMenuButton.icon<String>(
    icon: PlatformInfo.isIOS26OrHigher()
        ? 'ellipsis.circle'
        : Icons.more_vert_rounded,
    items: <AdaptivePopupMenuEntry>[
      AdaptivePopupMenuItem<String>(
        label: 'New list',
        icon: PlatformInfo.isIOS26OrHigher() ? 'plus' : Icons.add_rounded,
        value: 'new',
      ),
      AdaptivePopupMenuItem<String>(
        label: 'Rename list',
        icon: PlatformInfo.isIOS26OrHigher() ? 'pencil' : Icons.edit_outlined,
        value: 'rename',
      ),
      if (list.length > 0)
        AdaptivePopupMenuItem<String>(
          label: 'Empty list',
          icon: PlatformInfo.isIOS26OrHigher()
              ? 'minus.circle'
              : Icons.remove_circle_outline_rounded,
          value: 'empty',
        ),
      // The default list has to survive: a heart tap needs somewhere to land.
      if (!list.isDefault)
        AdaptivePopupMenuItem<String>(
          label: 'Delete list',
          icon: PlatformInfo.isIOS26OrHigher()
              ? 'trash'
              : Icons.delete_outline_rounded,
          value: 'delete',
        ),
    ],
    onSelected: (int _, AdaptivePopupMenuItem<String> entry) =>
        switch (entry.value) {
          'new' => onNew(),
          'rename' => onRename(),
          'empty' => onEmpty(),
          _ => onDelete(),
        },
  );
}
