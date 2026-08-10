import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/favorites_provider.dart';

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

  Future<void> _toggle() async {
    final bool added = await ref
        .read(favoritesProvider.notifier)
        .toggle(widget.productId);
    if (added) {
      unawaited(HapticFeedback.selectionClick());
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

    return Semantics(
      button: true,
      label: isFavorite ? 'Remove from wishlist' : 'Save to wishlist',
      child: InkResponse(
        onTap: _toggle,
        radius: widget.size + 12,
        child: widget.filledBackground
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
            : Padding(padding: const EdgeInsets.all(6), child: icon),
      ),
    );
  }
}
