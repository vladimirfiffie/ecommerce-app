import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Photos attached to reviews written on this device.
///
/// Guarded the same way haptics, notifications and biometrics are:
/// platform-checked and non-throwing. A camera roll that can't be opened, or a
/// disk that refuses the copy, must never be able to lose the review the
/// shopper actually typed — the words are the point, the photo is a bonus.
class ReviewPhotoService {
  ReviewPhotoService(this._picker);

  final ImagePicker _picker;

  /// How many a single review can carry. Enough to show a fit, a flaw and a
  /// detail; few enough that the row doesn't become a gallery.
  static const int maxPerReview = 4;

  /// Long side, in pixels. A phone photo is several megabytes and this is
  /// shown at thumbnail size in a list — storing the original would fill the
  /// device to say nothing more.
  static const double _maxDimension = 1440;

  static bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<T?> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      debugPrint('review photos unavailable: $error');
      return null;
    }
  }

  /// Picks up to [remaining] images and copies them somewhere they'll survive.
  ///
  /// The picker hands back a path in a cache the OS is free to empty, so the
  /// file is copied into the app's own documents directory before its path is
  /// written into a review that expects to outlive the session.
  Future<List<String>> pick({required int remaining}) async {
    if (!platformSupported || remaining <= 0) return const <String>[];

    final List<XFile>? picked = await _guard(
      () => _picker.pickMultiImage(
        limit: remaining,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: 85,
      ),
    );
    if (picked == null || picked.isEmpty) return const <String>[];

    final Directory? dir = await _guard(_photoDirectory);
    if (dir == null) return const <String>[];

    final List<String> saved = <String>[];
    for (final XFile file in picked.take(remaining)) {
      final String name =
          'review-${DateTime.now().microsecondsSinceEpoch}-${saved.length}.jpg';
      final String? path = await _guard(() async {
        final File copy = await File(file.path).copy('${dir.path}/$name');
        return copy.path;
      });
      if (path != null) saved.add(path);
    }
    return saved;
  }

  Future<Directory> _photoDirectory() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${docs.path}/review_photos');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Best-effort cleanup. A photo left behind costs a few hundred kilobytes;
  /// an exception here would cost the shopper their delete.
  Future<void> discard(Iterable<String> paths) async {
    for (final String path in paths) {
      await _guard(() async {
        final File file = File(path);
        if (file.existsSync()) await file.delete();
      });
    }
  }

  /// Empties the store — for "reset everything".
  Future<void> discardAll() async {
    if (!platformSupported) return;
    await _guard(() async {
      final Directory dir = await _photoDirectory();
      if (dir.existsSync()) await dir.delete(recursive: true);
    });
  }
}

final Provider<ImagePicker> imagePickerProvider = Provider<ImagePicker>(
  (Ref ref) => ImagePicker(),
);

final Provider<ReviewPhotoService> reviewPhotosProvider =
    Provider<ReviewPhotoService>(
      (Ref ref) => ReviewPhotoService(ref.watch(imagePickerProvider)),
    );
