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
    version: '0.16.0',
    headline: 'Aster the way your phone does things',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'animation_outlined',
        'The animations are back',
        'Moving between pages lost its transition in 0.15.1 — the new '
            'Material package and the router disagreed about where the '
            'animation came from, and nothing was left to draw one. Pages '
            'slide and the back gesture peels again.',
      ),
      ReleaseHighlight(
        'palette_outlined',
        'Controls that behave like your phone’s',
        'Switches, sliders, list rows, text fields, menus, alerts and the '
            'navigation bars are all drawn the way the platform draws them, '
            'through adaptive_platform_ui. On Android that is the Material '
            'you already had; the work is what lets an iPhone build look '
            'like an iPhone app rather than an Android one wearing a '
            'different colour. Where a control could not survive the swap it '
            'stayed Material — the quantity stepper keeps its hold-to-repeat '
            'because a tooltip would have taken that gesture.',
      ),
      ReleaseHighlight(
        'card_giftcard_rounded',
        'Type a gift card the way it is printed',
        'The code field puts the dashes and capitals in as you type, so '
            'ASTER-GIFT-25 read off a card can be typed however you like. '
            'Redeeming one now has haptics, and a refused code buzzes rather '
            'than only writing an error under the keyboard.',
      ),
      ReleaseHighlight(
        'tune_rounded',
        'Small things that were wrong',
        'The ZIP field brings up the number pad in the United States and a '
            'normal keyboard everywhere else, the address form leads each '
            'row with an icon, and Settings has one notifications entry '
            'instead of two that looked like the same thing.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.15.1',
    headline: 'Same shop, newer foundations',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'palette_outlined',
        'Built on the new Material',
        'Flutter is splitting Material Design out of the framework into its '
            'own package, and Aster now builds on it. Every screen is the '
            'screen it was — but the theme, including the palette Android '
            'takes from your wallpaper, is running on the newer foundation.',
      ),
      ReleaseHighlight(
        'animation_outlined',
        'Steadier loading',
        'The shimmer that runs while products load keeps its timing when it '
            'restarts, instead of jumping.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.15.0',
    headline: 'Money you already have, lists you actually keep, and Spanish',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'card_giftcard_rounded',
        'Gift cards and store credit',
        'Redeem a code and the balance goes towards your next order before '
            'any card is charged — all of it, if it stretches that far. '
            'Cancel an order and the credit comes straight back; return one '
            'and the share you paid with credit returns the same way.',
      ),
      ReleaseHighlight(
        'bookmarks_outlined',
        'More than one list',
        'Saved is now as many lists as you want to keep — gifts, next '
            'month, whatever you call them. Tapping the heart still saves in '
            'one tap; hold it to choose where something goes.',
      ),
      ReleaseHighlight(
        'notifications_active_outlined',
        'Nothing lost to a swiped-away notification',
        'A bell on Home with everything the shop has told you: '
            'confirmations, shipping, delivery, refunds. It is read off your '
            'orders rather than off what happened to get posted, so it is '
            'there whether or not you caught the notification at the time.',
      ),
      ReleaseHighlight(
        'show_chart_rounded',
        'What it has actually cost',
        'The product page notes the price each day you open it, and tells '
            'you the lowest and highest it has seen — and only ever what it '
            'has really watched, rather than a line implying a longer memory '
            'than it has.',
      ),
      ReleaseHighlight(
        'location_on_outlined',
        'Tell the courier where to leave it',
        'A drop-off choice and a note — a gate code, the blue door round '
            'the side — remembered between orders and printed on the '
            'receipt. Long-press the app icon for Orders, Saved, Search and '
            'Bag while you are there.',
      ),
      ReleaseHighlight(
        'photo_library_outlined',
        'Show what it looked like',
        'Reviews you write can carry up to four photos, which stay on this '
            'device. Sizes are a dropdown now instead of a wall of buttons, '
            'and the size guide lets you pick which chart to read.',
      ),
      ReleaseHighlight(
        'translate_rounded',
        'Ahora en español',
        'Aster speaks Spanish. The whole buy path — bag, checkout, orders, '
            'returns and receipts — follows the language your phone is set '
            'to, alongside the money and dates that already did.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.14.0',
    headline: 'Put things aside, line them up, get the best price',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'card_giftcard_rounded',
        'Save for later',
        'Move something out of your bag without giving up on it, and back '
            'again when you decide — with the size, color and quantity it '
            'had when you set it down.',
      ),
      ReleaseHighlight(
        'timer_outlined',
        'Best code applied for you',
        'The bag now names the code worth having and what it comes to, and '
            'checkout applies it if you haven’t picked one. Codes are ranked '
            'by what you actually pay, so a percentage that would cost you '
            'free shipping never wins.',
      ),
      ReleaseHighlight(
        'tune_rounded',
        'Compare, and find your size',
        'Hold any two or three products to lay them side by side, row by '
            'row. On clothing, three questions work out which size to try '
            'and pick it for you.',
      ),
      ReleaseHighlight(
        'receipt_long_outlined',
        'Five minutes to change your mind',
        'A live window on the order confirmation to cancel it outright or '
            'send it somewhere else — and any completed order can now be '
            'exported as a PDF receipt.',
      ),
      ReleaseHighlight(
        'help_outline_rounded',
        'Reviews and answers you can search',
        'Reviews say what they are about and who wrote it, with photos and '
            'filters, and there is a page for all of them and a page for '
            'yours. The help center is searchable, and the product page '
            'suggests what goes with a thing rather than more of it.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.13.1',
    headline: 'Same shop, better tested',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'bug_report_outlined',
        'Nothing new to look at',
        'The app is unchanged from 0.13.0. This build exists because the '
            'end-to-end tests had not been told about the new first-launch '
            'intro, so nothing was checking that a freshly installed copy '
            'gets from the intro through to the shop. It does, and now '
            'something checks every time.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.13.0',
    headline: 'Films, pinching, and a plus you can lean on',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'storefront_outlined',
        'A first launch that introduces itself',
        'Opening Aster for the first time now says what it is before it '
            'asks you to sign in: a demo shop, no payment ever taken, '
            'everything kept on your device. Skippable, and shown once.',
      ),
      ReleaseHighlight(
        'photo_library_outlined',
        'Video on the products that have it',
        'A clip leads the gallery, with the photos a swipe behind. Nothing '
            'downloads until you press play.',
      ),
      ReleaseHighlight(
        'search_rounded',
        'Pinch a photo where it already is',
        'Zooming no longer means opening another screen first — pinch the '
            'product image to 4× and pan around it. The corner button puts '
            'it back.',
      ),
      ReleaseHighlight(
        'tune_rounded',
        'Hold the plus instead of tapping thirty times',
        'Press and hold either side of the quantity control and it counts '
            'on its own, speeding up as it goes, stopping at the stock '
            'ceiling.',
      ),
      ReleaseHighlight(
        'animation_outlined',
        'No more pulsing quantity buttons',
        'Pressing plus or minus used to squash the glyph and spring it '
            'back. Nothing moves now — the button fills in under your thumb '
            'and stays filled while you hold it. The number beside it has '
            'stopped falling about too, and holds still entirely during a '
            'hold. The haptics screen also stops using a different switch '
            'for its main control than for everything under it.',
      ),
    ],
  ),
  ReleaseNote(
    version: '0.12.1',
    headline: 'Reads your accessibility settings, and your back gesture',
    highlights: <ReleaseHighlight>[
      ReleaseHighlight(
        'accessibility_new_rounded',
        'High contrast, if that is what you asked Android for',
        'Turn high contrast on in Android settings and Aster now rebuilds '
            'its palette to match, pushing text and its background as far '
            'apart as Material allows.',
      ),
      ReleaseHighlight(
        'animation_outlined',
        'Back you can see coming',
        'Dragging from the edge peels the page back far enough to show '
            'where you would land, and lets you change your mind — the '
            'gesture Android 14 introduced, instead of a plain fade.',
      ),
      ReleaseHighlight(
        'bug_report_outlined',
        'A build that gets built',
        'The v0.12.0 APKs never made it out: a test asserted the home '
            'screen says "Good morning" and the release ran at four in the '
            'morning UTC, when it says "Still up" instead.',
      ),
    ],
  ),
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
        'A help center that exists',
        'Profile → Help center used to promise itself for later. It now '
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
        'Aster now keeps the catalog on your device, so your bag, your '
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
        'The catalog is fetched fresh instead of shipped inside the app, '
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
        'Eight color themes',
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
