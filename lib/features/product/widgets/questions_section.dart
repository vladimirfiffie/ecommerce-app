import '../../../shared/widgets/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/product.dart';
import '../../../state/questions_provider.dart';

/// Questions and answers for a product, with a way to ask one.
class QuestionsSection extends ConsumerWidget {
  const QuestionsSection({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<ProductQuestion> questions = ref.watch(
      productQuestionsProvider(product.id),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Questions', style: theme.textTheme.titleLarge),
              const SizedBox(width: 8),
              Text(
                '(${questions.length})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => showAskQuestionSheet(context, product),
              icon: const Icon(Icons.help_outline_rounded, size: 18),
              label: const Text('Ask a question'),
            ),
          ),
          const SizedBox(height: 8),
          for (final ProductQuestion q in questions) _QuestionTile(question: q),
        ],
      ),
    );
  }
}

class _QuestionTile extends ConsumerWidget {
  const _QuestionTile({required this.question});

  final ProductQuestion question;

  String _age(DateTime when) {
    final int days = DateTime.now().difference(when).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 30) return '$days days ago';
    final int months = (days / 30).floor();
    return months == 1 ? '1 month ago' : '$months months ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(question.body, style: theme.textTheme.titleSmall),
              ),
              if (question.mine)
                IconButton(
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      ref.read(questionsProvider.notifier).remove(question.id),
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  <String>[
                    question.mine ? 'You' : 'A shopper',
                    _age(question.askedAt),
                  ].join('  ·  '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (question.isAnswered)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          question.answeredBy ?? 'Aster',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.answer!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          // Honest: there is no backend to answer it.
                          'Waiting for an answer — this demo has no support '
                          'team behind it.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showAskQuestionSheet(BuildContext context, Product product) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AskQuestionSheet(product: product),
      ),
    );

class AskQuestionSheet extends ConsumerStatefulWidget {
  const AskQuestionSheet({required this.product, super.key});

  final Product product;

  @override
  ConsumerState<AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends ConsumerState<AskQuestionSheet> {
  final TextEditingController _body = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String text = _body.text.trim();
    if (text.length < 8) {
      setState(() => _error = 'Give us a little more to go on');
      return;
    }
    await ref
        .read(questionsProvider.notifier)
        .ask(productId: widget.product.id, body: text);
    if (!mounted) return;
    Navigator.of(context).pop();
    showMessage(context, 'Question posted');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Ask about this', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              widget.product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _body,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              maxLength: 250,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Your question',
                hintText: 'Does this fit true to size?',
                errorText: _error,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _submit, child: const Text('Post')),
          ],
        ),
      ),
    );
  }
}
