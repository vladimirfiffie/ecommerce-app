import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_image.dart';
import 'product_video.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Swipeable product photos with page dots, plus a tap-to-zoom full screen view.
///
/// Any [videos] lead, on the platforms that can play them — a clip is the
/// thing worth seeing first, and the photos are one swipe behind it.
class ImageGallery extends StatefulWidget {
  const ImageGallery({
    required this.images,
    super.key,
    this.videos = const <String>[],
    this.heroTag,
  });

  final List<String> images;
  final List<String> videos;

  /// Applied to the first page only, so the transition from a product card
  /// lands on the image the shopper tapped.
  final String? heroTag;

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  final PageController _controller = PageController();

  /// Drives whichever page is on screen, so a pinch here zooms in place
  /// rather than making the shopper open the full screen view first.
  final TransformationController _transform = TransformationController();

  int _index = 0;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transform
      ..removeListener(_onTransformChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final bool zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  void _resetZoom() => _transform.value = Matrix4.identity();

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
    // Desktop has no player behind video_player, so there is nothing to put
    // on a video page there — the photos stand in for it.
    final List<String> videos = videoPlaybackSupported
        ? widget.videos
        : const <String>[];
    final int pages = videos.length + images.length;

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            // Locked while zoomed in, so dragging to look around a photo
            // doesn't slide the next one in from the side.
            physics: _zoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            onPageChanged: (int i) {
              _resetZoom();
              setState(() => _index = i);
            },
            itemCount: pages,
            itemBuilder: (BuildContext context, int page) {
              if (page < videos.length) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 84, 24, 44),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: ProductVideo(url: videos[page]),
                  ),
                );
              }

              // Photos start where the clips leave off, so the hero still
              // belongs to the first picture rather than the first page.
              final int index = page - videos.length;
              final Widget image = Padding(
                padding: const EdgeInsets.fromLTRB(24, 84, 24, 44),
                child: InteractiveViewer(
                  // Only the page on screen drives the shared controller.
                  transformationController: page == _index ? _transform : null,
                  minScale: 1,
                  maxScale: 4,
                  child: AppImage(
                    url: images[index],
                    fit: BoxFit.contain,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              );
              // Without this the gallery is a silent stack of unlabelled
              // pictures with no clue that tapping enlarges them.
              return Semantics(
                label: images.length == 1
                    ? AppL10n.of(context).productImage
                    : AppL10n.of(
                        context,
                      ).productImageOfCount(index + 1, images.length),
                image: true,
                button: true,
                onTapHint: AppL10n.of(context).enlargeHint,
                onTap: () => _openViewer(index),
                child: GestureDetector(
                  // While zoomed in place a tap would yank the photo away
                  // into another screen at a scale it doesn't share.
                  onTap: _zoomed ? null : () => _openViewer(index),
                  child: index == 0 && widget.heroTag != null
                      ? Hero(tag: widget.heroTag!, child: image)
                      : image,
                ),
              );
            },
          ),
          if (pages > 1)
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < pages; i++)
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
          // Nothing to zoom on a video page — that tap plays and pauses.
          if (_index >= videos.length)
            Positioned(
              bottom: 14,
              right: 16,
              // Zoomed in place, the hint becomes the way back out: the
              // gesture that got you here doesn't advertise its own undo,
              // and pinching back to exactly 1× is fiddly.
              child: _zoomed
                  ? _GalleryChip(
                      icon: Icons.zoom_out_rounded,
                      label: 'Reset',
                      onTap: _resetZoom,
                    )
                  : const _GalleryChip(
                      icon: Icons.zoom_out_map_rounded,
                      label: 'Pinch or tap to zoom',
                    ),
            ),
        ],
      ),
    );
  }
}

/// The small rounded label in the gallery's corner.
///
/// Inert unless [onTap] is given — the hint is a caption, the reset is a
/// button, and they sit in the same place.
class _GalleryChip extends StatelessWidget {
  const _GalleryChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13),
          const SizedBox(width: 5),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );

    if (onTap == null) return IgnorePointer(child: chip);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: chip,
      ),
    );
  }
}

/// Full-bleed viewer with pinch, double-tap and pan.
///
/// Page swiping is disabled while zoomed in — otherwise dragging to pan the
/// image also flips to the next photo, which makes a zoomed image impossible
/// to explore.
class _FullScreenViewer extends StatefulWidget {
  const _FullScreenViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer>
    with SingleTickerProviderStateMixin {
  static const double _doubleTapScale = 2.5;

  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  final TransformationController _transform = TransformationController();

  late final AnimationController _zoomController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  Animation<Matrix4>? _zoomAnimation;

  late int _index = widget.initialIndex;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _zoomController.addListener(() {
      final Matrix4? value = _zoomAnimation?.value;
      if (value != null) _transform.value = value;
    });
    _transform.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transform
      ..removeListener(_onTransformChanged)
      ..dispose();
    _zoomController.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final bool zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  void _animateTo(Matrix4 target) {
    _zoomAnimation = Matrix4Tween(begin: _transform.value, end: target).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeOutCubic),
    );
    _zoomController.forward(from: 0);
  }

  /// Zooms toward the tapped point, or back out if already zoomed.
  void _handleDoubleTap(TapDownDetails details, Size viewport) {
    if (_zoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    final Offset tap = details.localPosition;
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(
          -tap.dx * (_doubleTapScale - 1),
          -tap.dy * (_doubleTapScale - 1),
          0,
          1,
        )
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, _doubleTapScale, 1),
    );
  }

  void _resetZoom() {
    _zoomController.stop();
    _transform.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          if (_zoomed)
            IconButton(
              tooltip: 'Reset zoom',
              icon: const Icon(Icons.zoom_out_map_rounded),
              onPressed: () => _animateTo(Matrix4.identity()),
            ),
        ],
        title: widget.images.length > 1
            ? Text(
                '${_index + 1} / ${widget.images.length}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                ),
              )
            : null,
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size viewport = constraints.biggest;
          return PageView.builder(
            controller: _pages,
            // Locked while zoomed so panning doesn't change page.
            physics: _zoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            onPageChanged: (int i) {
              _resetZoom();
              setState(() => _index = i);
            },
            itemCount: widget.images.length,
            itemBuilder: (BuildContext context, int index) => GestureDetector(
              onDoubleTapDown: (TapDownDetails d) =>
                  _handleDoubleTap(d, viewport),
              // The handler lives on onDoubleTapDown so the tap position
              // is known; this just satisfies the recogniser.
              onDoubleTap: () {},
              child: InteractiveViewer(
                // Only the visible page drives the shared controller.
                transformationController: index == _index ? _transform : null,
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: AppImage(
                    url: widget.images[index],
                    fit: BoxFit.contain,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
