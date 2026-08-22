import 'package:material_ui/material_ui.dart';

import '../../../data/models/wish_list.dart';

/// The lists, across the top of the Saved tab.
///
/// Hidden while there is only one: a row of tabs with a single tab in it is
/// chrome explaining a choice nobody has made yet.
class ListStrip extends StatelessWidget {
  const ListStrip({
    required this.lists,
    required this.selectedId,
    required this.onSelect,
    required this.onNew,
    super.key,
  });

  final List<WishList> lists;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    if (lists.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        children: <Widget>[
          for (final WishList list in lists)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: list.id == selectedId,
                onSelected: (_) => onSelect(list.id),
                label: Text('${list.name} · ${list.length}'),
              ),
            ),
          ActionChip(
            onPressed: onNew,
            avatar: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New'),
          ),
        ],
      ),
    );
  }
}
