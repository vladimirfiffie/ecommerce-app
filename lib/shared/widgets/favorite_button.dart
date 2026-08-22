import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/favorites_provider.dart';
import '../../state/wishlists_provider.dart';
import '../../state/haptics_provider.dart';
import 'package:haptic_kit/haptic_kit.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../features/favorites/widgets/save_to_list_sheet.dart';

/// Heart toggle with a pop animation, wired straight to the wishlist.
class FavoriteButton extends ConsumerStatefulWidget {
  const FavoriteButton({
    required this.productId,
    super.key,
    this.size = 20,
    this.filledBackground = true,
  });

  final String productId;
  final double size;

  /// Draws a translucent circular backdrop, for hearts sitting over imagery.
  final bool filledBackground;

  /// Android's minimum tap target. The heart is drawn much smaller than this
  /// — an 18px icon in a 34px circle looks right on a product card and is a
  /// third short of what a thumb, or Android's own accessibility scanner,
  /// expects. The visual stays; the touchable box around it doesn't.
  static const double minTapTarget = 48;

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  late final Animation<double> _scale = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 1.35),
        weight: 40,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.35, end: 1),
        weight: 60,
      ),
    ],
    // The sequence supplies the overshoot itself; an overshooting curve like
    // easeOutBack would drive `t` outside [0, 1] and trip TweenSequence.
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A tap saves; a long press asks where.
  ///
  /// The sheet is the second gesture rather than the first because saving
  /// something has to stay one tap — being asked to pick a list every time
  /// turns a reflex into a decision.
  Future<void> _chooseList() async {
    unawaited(ref.read(hapticsProvider).impact(HapticImpactStyle.medium));
    await showSaveToListSheet(context, widget.productId);
  }

  Future<void> _toggle() async {
    final bool added = await ref
        .read(wishListsProvider.notifier)
        .toggle(widget.productId);
    if (added) {
      unawaited(ref.read(hapticsProvider).impact(HapticImpactStyle.light));
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isFavorite = ref.watch(isFavoriteProvider(widget.productId));

    final Widget icon = ScaleTransition(
      scale: _scale,
      child: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: widget.size,
        color: isFavorite
            ? const Color(0xFFE5484D)
            : theme.colorScheme.onSurfaceVariant,
      ),
    );

    final Widget visual = widget.filledBackground
        ? Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: icon,
          )
        : Padding(padding: const EdgeInsets.all(6), child: icon);

    return Semantics(
      button: true,
      label: isFavorite
          ? AppL10n.of(context).removeFromWishlist
          : AppL10n.of(context).saveToWishlist,
      onLongPressHint: 'Choose a list',
      child: SizedBox.square(
        dimension: FavoriteButton.minTapTarget,
        child: InkResponse(
          onTap: _toggle,
          onLongPress: _chooseList,
          radius: widget.size + 12,
          child: Center(child: visual),
        ),
      ),
    );
  }
}
