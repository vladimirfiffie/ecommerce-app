import '../../../shared/widgets/messages.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_kit/haptic_kit.dart';

import '../../../data/models/product.dart';
import '../../../shared/widgets/haptic_controls.dart';
import '../../../state/haptics_provider.dart';
import '../../../state/reviews_provider.dart';
import '../../../state/review_photos_provider.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/confirm.dart';

/// Opens the write/edit review sheet.
Future<void> showWriteReviewSheet(BuildContext context, Product product) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: WriteReviewSheet(product: product),
      ),
    );

class WriteReviewSheet extends ConsumerStatefulWidget {
  const WriteReviewSheet({required this.product, super.key});

  final Product product;

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late int _rating;
  late List<String> _photos;

  /// The photos this sheet copied to disk but hasn't attached to a saved
  /// review. Discarding the sheet has to take them with it, or a cancelled
  /// review leaves its pictures behind with nothing pointing at them.
  final List<String> _added = <String>[];
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final UserReview? existing = ref.read(myReviewProvider(widget.product.id));
    _rating = existing?.rating.round() ?? 0;
    _title = TextEditingController(text: existing?.title ?? '');
    _body = TextEditingController(text: existing?.body ?? '');
    _photos = <String>[...?existing?.photos];

    // Snapshot the opening state so "unsaved changes" means changed, not
    // merely non-empty — editing an existing review starts populated.
    _openedWith = (_rating, _title.text, _body.text, <String>[..._photos]);
  }

  late final (int, String, String, List<String>) _openedWith;

  bool get _dirty =>
      (_rating, _title.text.trim(), _body.text.trim()) !=
          (_openedWith.$1, _openedWith.$2.trim(), _openedWith.$3.trim()) ||
      !listEquals(_photos, _openedWith.$4);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      unawaited(
        ref.read(hapticsProvider).notification(HapticNotificationStyle.warning),
      );
      showMessage(context, 'Pick a star rating');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bool editing = ref.read(myReviewProvider(widget.product.id)) != null;
    final bool? post = await _confirm(
      title: editing ? 'Update your review?' : 'Post this review?',
      message: editing
          ? 'Your updated review replaces the one shoppers see now.'
          : 'Other shoppers will see this on ${widget.product.name}. You can '
                'edit or delete it afterwards.',
      confirmLabel: editing ? 'Update' : 'Post',
    );
    if (post != true || !mounted) return;

    await ref
        .read(userReviewsProvider.notifier)
        .save(
          UserReview(
            productId: widget.product.id,
            rating: _rating.toDouble(),
            title: _title.text.trim(),
            body: _body.text.trim(),
            writtenAt: DateTime.now(),
            photos: _photos,
          ),
        );
    // Saved: anything this sheet copied is now the review's problem, not
    // the sheet's.
    _added.clear();
    unawaited(
      ref.read(hapticsProvider).notification(HapticNotificationStyle.success),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    showMessage(context, 'Thanks for the review');
  }

  Future<void> _delete() async {
    final bool yes = await confirmDestructive(
      context,
      title: 'Delete your review?',
      message:
          'It will be removed from ${widget.product.name}. You can '
          'always write another.',
      confirmLabel: 'Delete',
    );
    if (!yes || !mounted) return;

    await ref.read(userReviewsProvider.notifier).delete(widget.product.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    showMessage(context, 'Review removed');
  }

  static const List<String> _hints = <String>[
    '',
    'What went wrong?',
    'What fell short?',
    'What was mixed about it?',
    'What did you like?',
    'What made it great?',
  ];

  /// Shared yes/no dialog. Returns null if dismissed.
  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            // Matches DangerButton's dialog sizing; the theme's 54px
            // minimum is for page buttons, not dialog actions.
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 40),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// Guards the sheet's dismissal when there's unsaved writing in it.
  Future<void> _maybeDiscard(bool didPop) async {
    if (didPop || !mounted) return;
    final bool discard = await confirmDestructive(
      context,
      title: 'Discard this review?',
      message: 'What you’ve written here won’t be saved.',
      confirmLabel: 'Discard',
    );
    if (!discard || !mounted) return;
    unawaited(ref.read(reviewPhotosProvider).discard(_added));
    Navigator.of(context).pop();
  }

  Future<void> _addPhotos() async {
    setState(() => _picking = true);
    final List<String> picked = await ref
        .read(reviewPhotosProvider)
        .pick(remaining: ReviewPhotoService.maxPerReview - _photos.length);
    if (!mounted) return;
    setState(() {
      _picking = false;
      _photos = <String>[..._photos, ...picked];
      _added.addAll(picked);
    });
  }

  /// Takes a photo off the review. The file only goes when the review is
  /// saved without it — dropping it here would strand an edit the shopper
  /// then backs out of.
  void _removePhoto(String path) => setState(
    () => _photos = <String>[
      for (final String p in _photos)
        if (p != path) p,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool editing = ref.watch(myReviewProvider(widget.product.id)) != null;

    return PopScope(
      // Only intercept when there's something to lose.
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, Object? _) =>
          unawaited(_maybeDiscard(didPop)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  editing ? 'Edit your review' : 'Write a review',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: AsterRating(
                    value: _rating,
                    size: 38,
                    onChanged: (int v) => setState(() => _rating = v),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _rating == 0 ? 'Tap to rate' : '$_rating out of 5',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Headline (optional)',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _body,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 600,
                  decoration: InputDecoration(
                    labelText: 'Your review',
                    hintText: _hints[_rating],
                    alignLabelWithHint: true,
                  ),
                  validator: (String? value) {
                    final String text = value?.trim() ?? '';
                    if (text.length < 10) {
                      return 'Tell us a bit more — at least 10 characters';
                    }
                    return null;
                  },
                ),
                if (ReviewPhotoService.platformSupported) ...<Widget>[
                  const SizedBox(height: 4),
                  _PhotoRow(
                    photos: _photos,
                    picking: _picking,
                    onAdd: _addPhotos,
                    onRemove: _removePhoto,
                  ),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submit,
                  child: Text(editing ? 'Update review' : 'Post review'),
                ),
                if (editing)
                  TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: const Text('Delete review'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thumbnails of what's attached, with a way to add more and drop one.
class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.photos,
    required this.picking,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final bool picking;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool room = photos.length < ReviewPhotoService.maxPerReview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('Photos', style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            Text(
              '${photos.length} of ${ReviewPhotoService.maxPerReview}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              for (final String path in photos)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 76,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: AppImage(
                            url: path,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            iconSize: 16,
                            tooltip: 'Remove photo',
                            onPressed: () => onRemove(path),
                            icon: CircleAvatar(
                              radius: 11,
                              backgroundColor: theme.colorScheme.surface,
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (room)
                SizedBox(
                  width: 76,
                  height: 76,
                  child: OutlinedButton(
                    onPressed: picking ? null : onAdd,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(76, 76),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: picking
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(Icons.add_a_photo_outlined, size: 20),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          // Worth saying plainly: there is no server, so a review photo has
          // nowhere to go even if the review reads as public.
          'Photos stay on this device.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
