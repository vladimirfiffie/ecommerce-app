import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';

/// Wraps children in the app's standard shimmer so every skeleton pulses in
/// sync and with the same colors.
class SkeletonShimmer extends StatelessWidget {
  const SkeletonShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.05),
        scheme.surfaceContainerHighest,
      ),
      child: child,
    );
  }
}

/// A solid rounded block that the shimmer paints over.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Placeholder shaped like a [ProductCard].
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1,
          child: SkeletonBox(
            height: double.infinity,
            radius: AppTheme.radiusMd,
          ),
        ),
        const SizedBox(height: 12),
        const SkeletonBox(width: 60, height: 9),
        const SizedBox(height: 8),
        const SkeletonBox(height: 12),
        const SizedBox(height: 6),
        const SkeletonBox(width: 110, height: 12),
        const SizedBox(height: 10),
        const SkeletonBox(width: 70, height: 15),
      ],
    ),
  );
}

/// Grid of [ProductCardSkeleton]s used while the catalog loads.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) => SkeletonShimmer(
    child: GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 22,
        crossAxisSpacing: 16,
        childAspectRatio: 0.54,
      ),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) =>
          const ProductCardSkeleton(),
    ),
  );
}

/// Horizontal rail of skeleton cards, matching the home page rails.
class ProductRailSkeleton extends StatelessWidget {
  const ProductRailSkeleton({
    super.key,
    this.height = 296,
    this.cardWidth = 168,
  });

  final double height;
  final double cardWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: SkeletonShimmer(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 16),
        itemBuilder: (BuildContext context, int index) =>
            ProductCardSkeleton(width: cardWidth),
      ),
    ),
  );
}
