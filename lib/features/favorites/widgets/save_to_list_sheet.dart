import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/wish_list.dart';
import '../../../state/wishlists_provider.dart';

/// Picks which lists something is saved to.
Future<void> showSaveToListSheet(BuildContext context, String productId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SaveToListSheet(productId: productId),
      ),
    );

class SaveToListSheet extends ConsumerStatefulWidget {
  const SaveToListSheet({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<SaveToListSheet> createState() => _SaveToListSheetState();
}

class _SaveToListSheetState extends ConsumerState<SaveToListSheet> {
  final TextEditingController _name = TextEditingController();
  bool _naming = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _createAndAdd() async {
    final String? id = await ref
        .read(wishListsProvider.notifier)
        .create(_name.text);
    if (id == null) return;
    await ref
        .read(wishListsProvider.notifier)
        .add(widget.productId, listId: id);
    if (!mounted) return;
    _name.clear();
    setState(() => _naming = false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<WishList> lists = ref.watch(wishListsProvider);
    final Set<String> selected = ref.watch(
      listsContainingProvider(widget.productId),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Save to', style: theme.textTheme.titleLarge),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (final WishList list in lists)
                    CheckboxListTile(
                      value: selected.contains(list.id),
                      onChanged: (bool? on) {
                        final WishListsNotifier notifier = ref.read(
                          wishListsProvider.notifier,
                        );
                        if (on ?? false) {
                          notifier.add(widget.productId, listId: list.id);
                        } else {
                          notifier.removeFrom(widget.productId, list.id);
                        }
                      },
                      title: Text(list.name),
                      subtitle: Text(
                        list.length == 1 ? '1 item' : '${list.length} items',
                      ),
                      secondary: Icon(
                        list.isDefault
                            ? Icons.favorite_rounded
                            : Icons.bookmark_outline_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (_naming)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _name,
                        autofocus: true,
                        maxLength: WishList.maxNameLength,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _createAndAdd(),
                        decoration: const InputDecoration(
                          labelText: 'List name',
                          hintText: 'Birthday ideas',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _createAndAdd,
                      child: const Text('Create'),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: TextButton.icon(
                  onPressed: () => setState(() => _naming = true),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('New list'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                // Said plainly, because an empty tick list looks the same as
                // an unsaved product and the heart outside says otherwise.
                selected.isEmpty
                    ? 'Not in any list — it won’t show on your Saved tab.'
                    : 'In ${selected.length} '
                          '${selected.length == 1 ? 'list' : 'lists'}.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
