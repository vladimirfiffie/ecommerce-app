import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/category.dart';

/// Scrollable row of icon tiles that jump into a filtered catalog.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    required this.categories,
    required this.onTap,
    super.key,
  });

  final List<Category> categories;
  final ValueChanged<Category> onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 14),
        itemBuilder: (BuildContext context, int index) {
          final Category category = categories[index];
          return SizedBox(
            width: 76,
            child: Column(
              children: <Widget>[
                Material(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: InkWell(
                    onTap: () => onTap(category),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: SizedBox(
                      height: 62,
                      width: 76,
                      child: Icon(
                        category.icon,
                        size: 26,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
