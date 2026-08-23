import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../../shared/widgets/adaptive_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/release_notes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/fade_up.dart';
import '../../shared/widgets/highlighted_text.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/haptics_provider.dart';
import '../whats_new/whats_new_sheet.dart';

/// FAQs and the one place that says, plainly, that this is a demo.
///
/// The answers are deliberately specific about what this build does and
/// doesn't do — a help center that promises a support desk nobody staffs is
/// worse than no help center at all.
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Topics with only the questions that match, topics with none dropped.
  ///
  /// Answers are searched as well as questions: people describe the problem
  /// they have, not the heading someone filed it under — "card" should find
  /// "Is a real payment ever taken?".
  List<_Topic> get _results {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return _topics;

    return <_Topic>[
      for (final _Topic topic in _topics)
        if (<_Faq>[
              for (final _Faq faq in topic.questions)
                if (faq.question.toLowerCase().contains(q) ||
                    faq.answer.toLowerCase().contains(q))
                  faq,
            ]
            case final List<_Faq> hits when hits.isNotEmpty)
          _Topic(title: topic.title, icon: topic.icon, questions: hits),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<_Topic> results = _results;
    final bool searching = _query.trim().isNotEmpty;

    final List<Widget> blocks = <Widget>[
      if (!searching) const _DemoNotice(),
      for (final _Topic topic in results)
        _TopicCard(topic: topic, query: _query, startExpanded: searching),
      if (searching && results.isEmpty) _NoResults(query: _query.trim()),
      if (!searching) const _ContactCard(),
    ];

    return AdaptiveScreen(
      title: 'Help center',
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (String value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search help',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searching
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _answerCount(results) == 1
                      ? '1 answer'
                      : '${_answerCount(results)} answers',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
              itemCount: blocks.length,
              separatorBuilder: (BuildContext context, int i) =>
                  const SizedBox(height: 20),
              // Short and fully built above, so the stagger runs straight
              // down it without the delays drifting as you scroll.
              itemBuilder: (BuildContext context, int i) =>
                  FadeUp.at(i, child: blocks[i]),
            ),
          ),
        ],
      ),
    );
  }

  int _answerCount(List<_Topic> topics) =>
      topics.fold(0, (int sum, _Topic t) => sum + t.questions.length);
}

/// Nothing matched — with the way to reach a person still in reach.
class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        const SizedBox(height: 24),
        Icon(
          Icons.search_off_rounded,
          size: 40,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text('Nothing about “$query”', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(
          'Try a shorter word, or report it on GitHub — an unanswered '
          'question is usually a missing answer.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// One question and the answer to it.
class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}

class _Topic {
  const _Topic({
    required this.title,
    required this.icon,
    required this.questions,
  });

  final String title;
  final IconData icon;
  final List<_Faq> questions;
}

/// Written against what the app actually does. If behavior changes, these
/// change with it.
final List<_Topic> _topics = <_Topic>[
  const _Topic(
    title: 'Orders & delivery',
    icon: Icons.local_shipping_outlined,
    questions: <_Faq>[
      _Faq(
        'Where is my order?',
        'Profile → Your orders lists every order you have placed, newest '
            'first. Open one to see where it has got to and to download a '
            'receipt. Status moves on by itself as the estimated delivery '
            'date approaches.',
      ),
      _Faq(
        'Do I need an account to buy something?',
        'No. Checkout works as a guest, and your bag, wishlist and orders '
            'are kept either way. Signing in only keeps your details '
            'together in one place.',
      ),
      _Faq(
        'Can I change or cancel an order?',
        'Not in this build. Once an order is placed the only route back is '
            'a return, which opens as soon as the order is marked delivered.',
      ),
    ],
  ),
  _Topic(
    title: 'Returns & refunds',
    icon: Icons.assignment_return_outlined,
    questions: <_Faq>[
      _Faq(
        'How long do I have to return something?',
        '${Order.returnWindow.inDays} days from the day an order is marked '
            'delivered. Open the order and choose Return — the screen shows '
            'the days you have left while the window is still open.',
      ),
      const _Faq(
        'When does a refund arrive?',
        'Refunds are shown as landing about five working days after the '
            'return is requested. The exact date appears on the return once '
            'you have submitted it.',
      ),
      const _Faq(
        'Can I return part of an order?',
        'Yes. The return screen lets you pick the individual items rather '
            'than sending the whole order back.',
      ),
    ],
  ),
  const _Topic(
    title: 'Payment & security',
    icon: Icons.credit_card_outlined,
    questions: <_Faq>[
      _Faq(
        'Is a real payment ever taken?',
        'No. Aster is a demo storefront with no server behind it, so no '
            'money moves and no card is ever charged. Use a test card '
            'number rather than a real one.',
      ),
      _Faq(
        'Why is it asking for my fingerprint?',
        'Only if you turned on payment verification in Settings → '
            'Security. The check happens entirely on your device — Aster is '
            'told whether the device said yes, and nothing more.',
      ),
      _Faq(
        'Where are my saved cards kept?',
        'On this device, alongside everything else. They never leave it, '
            'and full numbers are not stored.',
      ),
    ],
  ),
  const _Topic(
    title: 'Your data',
    icon: Icons.lock_outline_rounded,
    questions: <_Faq>[
      _Faq(
        'What does Aster store about me?',
        'Your bag, wishlist, orders, addresses, cards, searches and '
            'settings — all on this device only. There is no account '
            'server and nothing is uploaded.',
      ),
      _Faq(
        'What happens if I sign out?',
        'Nothing is lost. Your bag, wishlist and orders stay on this '
            'device and are waiting when you sign back in.',
      ),
      _Faq(
        'How do I clear everything?',
        'Settings → Your data has both options: clearing browsing history '
            'on its own, or resetting the bag, wishlist, orders, cards and '
            'history together.',
      ),
    ],
  ),
  const _Topic(
    title: 'The app',
    icon: Icons.phone_iphone_rounded,
    questions: <_Faq>[
      _Faq(
        'Why do some images take a moment?',
        'Product details ship inside the app, but imagery is fetched from '
            'a public CDN and cached after the first look. On a poor '
            'connection the first load is the slow one.',
      ),
      _Faq(
        'Can I turn the vibrations off?',
        'Settings → Haptics controls how much the app buzzes, including '
            'switching it off entirely. Notifications have their own '
            'screen next to it.',
      ),
    ],
  ),
];

/// The headline answer, said once at the top so nobody has to find it inside
/// an expander.
class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.auto_awesome_rounded,
            size: 22,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Aster is a demo storefront',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nothing is shipped and no payment is ever taken. '
                  'Everything you do stays on this device.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    this.query = '',
    this.startExpanded = false,
  });

  final _Topic topic;
  final String query;

  /// Search results open on the answer: the question was the search.
  final bool startExpanded;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(topic.icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: SectionHeader(
                title: topic.title,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AdaptiveCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: <Widget>[
                for (final _Faq faq in topic.questions)
                  _FaqTile(
                    // Keyed by the query so a tile left open by one search
                    // does not stay open for the next.
                    key: ValueKey<String>('${faq.question}|$query'),
                    faq: faq,
                    query: query,
                    startExpanded: startExpanded,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends ConsumerWidget {
  const _FaqTile({
    required this.faq,
    super.key,
    this.query = '',
    this.startExpanded = false,
  });

  final _Faq faq;
  final String query;
  final bool startExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return AdaptiveExpansionTile(
      // A tick as the answer opens, the same as every other control that
      // reveals something. Routed through the service, so the shopper's
      // channel and intensity settings apply here as anywhere else.
      onExpansionChanged: (bool _) =>
          unawaited(ref.read(hapticsProvider).selection()),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      initiallyExpanded: startExpanded,
      title: HighlightedText(
        text: faq.question,
        query: query,
        maxLines: 3,
        style: theme.textTheme.titleSmall,
      ),
      children: <Widget>[
        Text(
          faq.answer,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Where a real storefront would put a support number.
class _ContactCard extends ConsumerWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    // Leaving for a browser or opening a sheet is a press, not a tick.
    void tapped() => unawaited(ref.read(hapticsProvider).impact());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(
          title: 'Still stuck?',
          subtitle:
              'There is no support desk behind a demo — but the code '
              'is open, and bugs are welcome.',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 10),
        AdaptiveCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.bug_report_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    'Report an issue',
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    'Opens GitHub in your browser',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () {
                    tapped();
                    unawaited(
                      launchUrl(
                        Uri.parse(
                          'https://github.com/vladimirfiffie/'
                          'ecommerce-app/issues',
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.auto_awesome_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text('What’s new', style: theme.textTheme.titleSmall),
                  subtitle: Text(
                    'Version $currentReleaseVersion',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    tapped();
                    unawaited(
                      showWhatsNewSheet(
                        context,
                        notes: kReleaseNotes,
                        offerMute: false,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
