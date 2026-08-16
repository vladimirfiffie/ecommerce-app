/// One version's worth of "what's new".
///
/// Deliberately free of Flutter imports: `tool/generate_release_notes.dart`
/// reads this file to build the GitHub release body, so the in-app sheet and
/// the published notes can never drift apart.
class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.headline,
    required this.highlights,
  });

  /// Semantic version, matching `pubspec.yaml`. A test asserts they agree.
  final String version;

  final String headline;
  final List<ReleaseHighlight> highlights;
}

class ReleaseHighlight {
  const ReleaseHighlight(this.icon, this.title, this.body);

  /// Icon key, mapped to an `IconData` by the UI.
  final String icon;
  final String title;
  final String body;
}

/// Newest first. The first entry is treated as the current version, so this
/// list is the source of truth for whether an update has been seen.
const List<ReleaseNote> kReleaseNotes = <ReleaseNote>[
  ReleaseNote(
    version: '0.12.0',
    headline: 'The shop is called Aster now',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'auto_awesome_rounded',
        'New name, new mark',
        'Nova is Aster, from the sign-in screen to the icon on your home '
            'screen — a twelve-rayed flower on the same purple the rest of '
            'the app is built from, with a launch screen to match.',
      ),
      ReleaseHighlight(
        'help_outline_rounded',
        'A help centre that exists',
        'Profile → Help centre used to promise itself for later. It now '
            'opens on answers about orders, returns, payment and what we '
            'keep on your device — written against what the app really does.',
      ),
      ReleaseHighlight(
        'grid_view_rounded',
        'Tabs without the words',
        'Settings → Appearance can drop the labels under the bottom bar for '
            'icons alone, and the side rail on a tablet collapses with them. '
            'Screen readers still announce every tab by name.',
      ),
      ReleaseHighlight(
        'warning_amber_rounded',
        'Worth knowing before you update',
        'The rename reaches the package name and the aster:// links, so '
            'Android sees a new app: uninstall the old Nova build first, and '
            'any nova:// link you had saved stops opening the shop.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.11.1',
    headline: 'A quantity control that behaves',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'bug_report_outlined',
        'No more bin that deletes nothing',
        'On a product page the minus used to turn into a bin at one and '
            'then do nothing at all when you tapped it. The bin now appears '
            'only in your bag, where it really does take the item out.',
      ),
      ReleaseHighlight(
        'animation_outlined',
        'It moves now',
        'The number rolls the way you are counting, the buttons press in '
            'and spring back under your thumb, and one that has nothing left '
            'to do fades out instead of blinking. All of it holds still if '
            'you have asked your phone to reduce motion.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.11.0',
    headline: 'Works offline, and reads out loud',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'cloud_off_rounded',
        'The shop opens without a signal',
        'Aster now keeps the catalogue on your device, so your bag, your '
            'saved items and your orders still open with no connection. When '
            'something genuinely can’t be reached it says so, instead of '
            'looking like you own nothing.',
      ),
      ReleaseHighlight(
        'receipt_long_outlined',
        'Receipts that stay true',
        'An order now remembers what you actually paid. A price change in '
            'the shop can no longer rewrite an old receipt, and an item that '
            'stops being sold can no longer vanish from one.',
      ),
      ReleaseHighlight(
        'accessibility_new_rounded',
        'Built for screen readers',
        'A product now reads as one sentence rather than six fragments, sale '
            'prices say which figure is the old one, and the stars, steppers '
            'and photos all have names. Buttons meet the minimum tap size.',
      ),
      ReleaseHighlight(
        'translate_rounded',
        'Your format for money and dates',
        'Prices and dates now follow your device’s region instead of always '
            'being written the American way.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.10.0',
    headline: 'Home knows where your parcel is',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'assignment_return_outlined',
        'Track it from home',
        'Your open order sits at the top of home with a progress tracker '
            'and its arrival date — plus the days left to return a delivery, '
            'and when a refund is due back.',
      ),
      ReleaseHighlight(
        'card_giftcard_rounded',
        'Better nudges',
        'Home now tells you when something you saved is nearly gone, and '
            'how much further your bag has to go for free delivery.',
      ),
      ReleaseHighlight(
        'location_on_outlined',
        'Addresses that get checked',
        'The address form now catches typos as you save rather than after '
            'the parcel goes astray.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.9.0',
    headline: 'Know what you’re buying',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'storefront_outlined',
        'Brand pages',
        'Tap the brand on any product to see everything it sells, with its '
            'rating, cheapest price and how many are on sale.',
      ),
      ReleaseHighlight(
        'tune_rounded',
        'Specifications',
        'Products now list their size, weight, warranty, shipping and '
            'returns — no more guessing what turns up in the box.',
      ),
      ReleaseHighlight(
        'bug_report_outlined',
        'A fix',
        'The deals line on a product page no longer runs off the edge of '
            'narrow screens.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.8.0',
    headline: 'A proper front door',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'storefront_outlined',
        'Sign in, or don’t',
        'Aster now opens on sign in and create account, with one tap to '
            'browse as a guest — and it remembers which you chose.',
      ),
      ReleaseHighlight(
        'assignment_return_outlined',
        'Orders that keep up',
        'Your orders now shows the newest one, where it’s got to and when '
            'it lands, and it updates itself while you watch.',
      ),
      ReleaseHighlight(
        'vibration_rounded',
        'A tidier Settings',
        'The haptics screen is now just the controls — master switch, '
            'strength and what gets feedback.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.7.0',
    headline: 'A home that knows you',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'auto_awesome_rounded',
        'For you',
        'Back-in-stock items you watched, price drops on things you saved, '
            'and what’s still in your bag — all on the home screen.',
      ),
      ReleaseHighlight(
        'timer_outlined',
        'Deals that actually end',
        'Today’s deals rotate at midnight, with a live countdown on home '
            'and on the products in it.',
      ),
      ReleaseHighlight(
        'grid_view_rounded',
        'A calmer home',
        'Fewer stacked carousels, and categories live in one place instead '
            'of three.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.6.0',
    headline: 'Search that finds things',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'search_rounded',
        'Better search',
        'Word order no longer matters, the best match comes first, and the '
            'words you typed are picked out in the results.',
      ),
      ReleaseHighlight(
        'grid_view_rounded',
        'Grid or list, your choice',
        'Search results follow the same view toggle as the shop.',
      ),
      ReleaseHighlight(
        'photo_library_outlined',
        'Browse by picture',
        'Category artwork replaces the old word chips on the search screen.',
      ),
      ReleaseHighlight(
        'tune_rounded',
        'Fewer duplicates',
        'One word for the bag, one home for each setting, and the crowded '
            'home header is gone.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.5.0',
    headline: 'Pull for fresh stock',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'refresh_rounded',
        'Pull to refresh',
        'Drag down on the shop, home, saved or search to fetch the latest '
            'products — with a tick when it lands.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.4.1',
    headline: 'Clearer warnings',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'warning_amber_rounded',
        'Deleting looks like deleting',
        'Anything that removes, cancels or signs you out is red now, and '
            'asks first.',
      ),
      ReleaseHighlight(
        'assignment_return_outlined',
        'Cancelled orders say so',
        'No more delivery estimate on an order that isn’t coming.',
      ),
      ReleaseHighlight(
        'photo_library_outlined',
        'See what you bought',
        'The confirmation screen shows the items, not just a total.',
      ),
      ReleaseHighlight(
        'tune_rounded',
        'Tidier Profile',
        'Orders, addresses and cards each live in one place instead of two.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.4.0',
    headline: 'A real shop, and room to breathe',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'cloud_download_outlined',
        'Live products',
        'The catalogue is fetched fresh instead of shipped inside the app, '
            'so the shop needs a connection now.',
      ),
      ReleaseHighlight(
        'tablet_mac_rounded',
        'Two panes everywhere',
        'Shop, Saved, Search, Orders, Checkout and Settings all keep the '
            'list in place on a tablet.',
      ),
      ReleaseHighlight(
        'animation_outlined',
        'Smoother checkout',
        'The progress bar fills as you go, and the confirmation tick draws '
            'itself.',
      ),
      ReleaseHighlight(
        'bug_report_outlined',
        'Layout fixes',
        'The order tracker no longer overflows, and product cards size '
            'correctly beside a detail pane.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.3.0',
    headline: 'Orders you can actually manage',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'assignment_return_outlined',
        'Returns and cancellations',
        'Cancel before dispatch, or send items back within 30 days with a '
            'live refund estimate.',
      ),
      ReleaseHighlight(
        'credit_card_rounded',
        'Saved cards and delivery choices',
        'Add a card once, then pick standard, express or collect in store.',
      ),
      ReleaseHighlight(
        'card_giftcard_rounded',
        'Gift wrap and messages',
        'Send it straight to someone, with prices left off the packing slip.',
      ),
      ReleaseHighlight(
        'help_outline_rounded',
        'Size guides and questions',
        'Check the fit before you buy, and ask about anything else.',
      ),
      ReleaseHighlight(
        'notifications_active_outlined',
        'Back-in-stock alerts',
        'Watch a sold-out item and get told the moment it returns.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.2.0',
    headline: 'Make it yours',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'palette_outlined',
        'Eight colour themes',
        'Plus AMOLED black, and Material You on Android 12+.',
      ),
      ReleaseHighlight(
        'vibration_rounded',
        'Haptics you control',
        'Three strengths and four switchable channels.',
      ),
      ReleaseHighlight(
        'fingerprint_rounded',
        'Verify before paying',
        'Optional biometric confirmation at checkout.',
      ),
      ReleaseHighlight(
        'tablet_mac_rounded',
        'Built for bigger screens',
        'A navigation rail and two-pane layouts on tablets.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.1.0',
    headline: 'Welcome to Aster',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'storefront_outlined',
        'The shop',
        '157 products, search, filters, wishlist and checkout.',
      ),
    ],
  ),
];

/// The version the app currently considers itself to be.
String get currentReleaseVersion => kReleaseNotes.first.version;

/// Compares dotted numeric versions. Returns <0, 0 or >0.
///
/// Missing segments count as zero, so `1.2` and `1.2.0` are equal, and any
/// non-numeric segment sorts as zero rather than throwing.
int compareVersions(String a, String b) {
  final List<String> x = a.split('.');
  final List<String> y = b.split('.');
  final int length = x.length > y.length ? x.length : y.length;

  for (int i = 0; i < length; i++) {
    final int left = i < x.length ? (int.tryParse(x[i]) ?? 0) : 0;
    final int right = i < y.length ? (int.tryParse(y[i]) ?? 0) : 0;
    if (left != right) return left.compareTo(right);
  }
  return 0;
}

/// Notes newer than [sinceVersion], so an upgrade that skipped a release
/// still shows everything that changed.
List<ReleaseNote> releaseNotesSince(String? sinceVersion) {
  if (sinceVersion == null) return const <ReleaseNote>[];
  return <ReleaseNote>[
    for (final ReleaseNote note in kReleaseNotes)
      if (compareVersions(note.version, sinceVersion) > 0) note,
  ];
}
