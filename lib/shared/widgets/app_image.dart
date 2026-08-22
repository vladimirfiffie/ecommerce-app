import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

/// Product imagery with a consistent loading shimmer and offline fallback.
///
/// Every remote image in the app goes through here so caching, placeholders and
/// failure states never drift between screens.
///
/// A photo the shopper attached to their own review is a file on this device
/// rather than a URL, and arrives here by the same field. It is told apart by
/// its path rather than by the caller, so nothing upstream has to know which
/// kind of picture it is holding — and a file that has since been deleted
/// falls back to the same placeholder a dead URL does.
class AppImage extends StatelessWidget {
  const AppImage({
    required this.url,
    super.key,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color bg = backgroundColor ?? scheme.surfaceContainerHighest;

    Widget child;
    if (url.isEmpty) {
      child = _Fallback(background: bg);
    } else if (isLocalImagePath(url)) {
      child = Image.file(
        File(url),
        fit: fit,
        errorBuilder: (BuildContext context, Object _, StackTrace? _) =>
            _Fallback(background: bg),
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 220),
        placeholder: (BuildContext context, String _) =>
            ImageSkeleton(background: bg),
        errorWidget: (BuildContext context, String _, Object _) =>
            _Fallback(background: bg),
      );
    }

    return ColoredBox(
      color: bg,
      child: borderRadius == null
          ? child
          : ClipRRect(borderRadius: borderRadius!, child: child),
    );
  }
}

/// Whether [url] names a file on this device rather than something to fetch.
bool isLocalImagePath(String url) =>
    url.startsWith('/') || url.startsWith('file:');

/// The shimmering block shown while an image loads.
class ImageSkeleton extends StatelessWidget {
  const ImageSkeleton({super.key, this.background});

  final Color? background;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color base = background ?? scheme.surfaceContainerHighest;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.06),
        base,
      ),
      child: ColoredBox(color: base, child: const SizedBox.expand()),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.background});

  final Color background;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: background,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          size: 28,
        ),
      ),
    );
  }
}
