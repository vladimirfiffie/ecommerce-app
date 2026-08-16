import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_kit/haptic_kit.dart';

import '../../../data/models/product.dart';
import '../../../shared/widgets/haptic_controls.dart';
import '../../../state/haptics_provider.dart';
import '../../../state/reviews_provider.dart';
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

  @override
  void initState() {
    super.initState();
    final UserReview? existing = ref.read(myReviewProvider(widget.product.id));
    _rating = existing?.rating.round() ?? 0;
    _title = TextEditingController(text: existing?.title ?? '');
    _body = TextEditingController(text: existing?.body ?? '');

    // Snapshot the opening state so "unsaved changes" means changed, not
    // merely non-empty — editing an existing review starts populated.
    _openedWith = (_rating, _title.text, _body.text);
  }

  late final (int, String, String) _openedWith;

  bool get _dirty =>
      (_rating, _title.text.trim(), _body.text.trim()) !=
      (_openedWith.$1, _openedWith.$2.trim(), _openedWith.$3.trim());

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
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Pick a star rating')));
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
          ),
        );
    unawaited(
      ref.read(hapticsProvider).notification(HapticNotificationStyle.success),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Thanks for the review')));
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
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Review removed')));
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
    if (discard && mounted) Navigator.of(context).pop();
  }

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
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Headline (optional)',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _body,
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
