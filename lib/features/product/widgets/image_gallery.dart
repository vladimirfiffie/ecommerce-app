import 'package:flutter/material.dart';

import '../../../shared/widgets/app_image.dart';

/// Swipeable product photos with page dots, plus a tap-to-zoom full screen view.
class ImageGallery extends StatefulWidget {
  const ImageGallery({required this.images, super.key, this.heroTag});

  final List<String> images;

  /// Applied to the first page only, so the transition from a product card
  /// lands on the image the shopper tapped.
  final String? heroTag;

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, Animation<double> animation, _) =>
            FadeTransition(
              opacity: animation,
              child: _FullScreenViewer(
                images: widget.images,
                initialIndex: initialIndex,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> images = widget.images.isEmpty
        ? const <String>['']
        : widget.images;

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            onPageChanged: (int i) => setState(() => _index = i),
            itemCount: images.length,
            itemBuilder: (BuildContext context, int index) {
              final Widget image = Padding(
                padding: const EdgeInsets.fromLTRB(24, 84, 24, 44),
                child: AppImage(
                  url: images[index],
                  fit: BoxFit.contain,
                  backgroundColor: Colors.transparent,
                ),
              );
              return GestureDetector(
                onTap: () => _openViewer(index),
                child: index == 0 && widget.heroTag != null
                    ? Hero(tag: widget.heroTag!, child: image)
                    : image,
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: i == _index ? 20 : 6,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
            ),
          Positioned(
            bottom: 14,
            right: 16,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.zoom_out_map_rounded, size: 13),
                    const SizedBox(width: 5),
                    Text('Tap to zoom', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinch-zoomable full-bleed viewer.
class _FullScreenViewer extends StatelessWidget {
  const _FullScreenViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    extendBodyBehindAppBar: true,
    body: PageView.builder(
      controller: PageController(initialPage: initialIndex),
      itemCount: images.length,
      itemBuilder: (BuildContext context, int index) => InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Center(
          child: AppImage(
            url: images[index],
            fit: BoxFit.contain,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    ),
  );
}
