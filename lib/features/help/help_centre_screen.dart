import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/release_notes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/fade_up.dart';
import '../../shared/widgets/section_header.dart';
import '../whats_new/whats_new_sheet.dart';

/// FAQs and the one place that says, plainly, that this is a demo.
///
/// The answers are deliberately specific about what this build does and
/// doesn't do — a help centre that promises a support desk nobody staffs is
/// worse than no help centre at all.
class HelpCentreScreen extends StatelessWidget {
  const HelpCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> blocks = <Widget>[
      const _DemoNotice(),
      for (final _Topic topic in _topics) _TopicCard(topic: topic),
      const _ContactCard(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Help centre')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        itemCount: blocks.length,
        separatorBuilder: (BuildContext context, int i) =>
            const SizedBox(height: 20),
        // The list is short and fully built above, so the stagger can run
        // straight down it without the delays drifting as you scroll.
        itemBuilder: (BuildContext context, int i) =>
            FadeUp.at(i, child: blocks[i]),
      ),
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

/// Written against what the app actually does. If behaviour changes, these
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
  const _TopicCard({required this.topic});

  final _Topic topic;

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
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: <Widget>[
                for (final _Faq faq in topic.questions) _FaqTile(faq: faq),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq});

  final _Faq faq;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ExpansionTile(
      // The default outline draws a box inside the card it already sits in.
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Text(faq.question, style: theme.textTheme.titleSmall),
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
class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
        Card(
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
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://github.com/vladimirfiffie/ecommerce-app/issues',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
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
                  onTap: () => showWhatsNewSheet(
                    context,
                    notes: kReleaseNotes,
                    offerMute: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
