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
    headline: 'Welcome to Nova',
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
