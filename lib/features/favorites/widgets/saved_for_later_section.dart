import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cart_item.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/saved_for_later_provider.dart';

/// The things put aside from the bag, wherever they are being shown.
///
/// Lived inside the bag screen, which made it a footer of the bag rather than
/// a place — Settings could only reach it by throwing the shopper into
/// another tab. It has its own section on the Saved tab now, and the bag
/// still shows it underneath, which is where it is set aside from.
class SavedForLaterSection extends ConsumerWidget {
  const SavedForLaterSection({super.key, this.showHeader = true});

  /// Whether to draw its own heading.
  ///
  /// The bag needs one — the section sits under the bag's own list and has
  /// to say what it is. The Saved tab doesn't; there the section *is* the
  /// page, and a heading under the tab's own title says it twice.
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<CartItem> saved = ref.watch(savedForLaterItemsProvider);
    if (saved.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showHeader) ...<Widget>[
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SectionHeader(
              title: AppL10n.of(context).savedForLaterTitle,
              subtitle: AppL10n.of(context).savedForLaterCount(saved.length),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 10),
        ],
        for (final CartItem item in saved)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AdaptiveCard(
              child: ProductRow(
                product: item.product,
                heroPrefix: 'saved',
                subtitle: item.variantLabel == null
                    ? null
                    : Text(item.variantLabel!),
                // Bounded, and the label allowed to ellipsize inside it. The
                // price, a remove button and "Move to bag" laid out at their
                // natural widths overflow a 360dp phone by twenty-one
                // pixels — which was true in the bag too, where this section
                // used to live, and had never been rendered that narrow.
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        formatPrice(item.lineTotal),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            tooltip: AppL10n.of(context).removeItem,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => ref
                                .read(savedForLaterProvider.notifier)
                                .remove(item.lineId),
                          ),
                          Flexible(
                            child: FilledButton.tonal(
                              onPressed: () => ref
                                  .read(savedForLaterProvider.notifier)
                                  .moveToBag(item.entry),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                AppL10n.of(context).savedMoveToBag,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
