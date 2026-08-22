import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

/// Whether a clip can actually be played here.
///
/// `video_player` ships implementations for Android, iOS and web — there is
/// none for Linux desktop, where a controller would fail on create. The
/// gallery asks this before offering a video page at all, so on the desktop
/// build a product with a clip simply shows its photos.
///
/// Read from [defaultTargetPlatform] rather than `dart:io`: the desktop build
/// reports linux either way, and this is the one a test can state.
bool get videoPlaybackSupported {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// A single product clip: a still frame until it is asked for, then playback
/// with a scrub bar.
///
/// Nothing is fetched until the shopper taps play. A product page that
/// autoplayed would cost data on a connection nobody chose to spend it on,
/// and the gallery it sits in is scrolled past far more often than watched.
class ProductVideo extends StatefulWidget {
  const ProductVideo({required this.url, super.key});

  final String url;

  /// How long to wait for the first frame before giving up.
  ///
  /// A dead URL usually errors, but a stalled connection leaves
  /// [VideoPlayerController.initialize] waiting on a frame that never
  /// arrives — without this the page spins for as long as anyone watches it.
  static const Duration timeout = Duration(seconds: 15);

  @override
  State<ProductVideo> createState() => _ProductVideoState();
}

class _ProductVideoState extends State<ProductVideo> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_loading || _controller != null) return;
    setState(() => _loading = true);

    // Creating the controller is inside the try as well: on a platform with
    // no implementation behind video_player that is where it fails, and an
    // escaped error there would leave this spinning forever.
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize().timeout(ProductVideo.timeout);
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } on Object {
      // A clip that will not load is not worth an error dialog over a
      // product page — the photos are still right there.
      //
      // Say so first and clean up after. Disposing a controller that never
      // finished being created waits on a completer that will never
      // complete, so awaiting it here would strand the page on its spinner
      // — the one state this catch exists to get out of.
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      unawaited(controller?.dispose().catchError((Object _) {}));
    }
  }

  void _togglePlaying() {
    final VideoPlayerController? controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final VideoPlayerController? controller = _controller;

    if (controller == null) {
      return _Placeholder(
        loading: _loading,
        failed: _failed,
        onPlay: _failed ? null : _start,
      );
    }

    return GestureDetector(
      onTap: _togglePlaying,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            // Only while paused, so a playing clip is left alone.
            if (!controller.value.isPlaying)
              const _PlayBadge(icon: Icons.play_arrow_rounded),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: theme.colorScheme.primary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.loading,
    required this.failed,
    required this.onPlay,
  });

  final bool loading;
  final bool failed;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: switch ((loading, failed)) {
          (true, _) => const CircularProgressIndicator(),
          (_, true) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.videocam_off_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'This clip would not load',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          _ => Semantics(
            button: true,
            label: 'Play video',
            child: InkResponse(
              onTap: onPlay,
              radius: 48,
              child: const _PlayBadge(icon: Icons.play_arrow_rounded),
            ),
          ),
        },
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: const BoxDecoration(
      color: Colors.black54,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 34, color: Colors.white),
  );
}
