import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/release_notes.dart';
import '../../core/theme/app_theme.dart';
import '../../state/whats_new_provider.dart';

/// Icon keys from [ReleaseHighlight] resolved to real icons. Kept const so
/// unused glyphs are still tree-shaken.
const Map<String, IconData> _icons = <String, IconData>{
  'assignment_return_outlined': Icons.assignment_return_outlined,
  'credit_card_rounded': Icons.credit_card_rounded,
  'location_on_outlined': Icons.location_on_outlined,
  'card_giftcard_rounded': Icons.card_giftcard_rounded,
  'help_outline_rounded': Icons.help_outline_rounded,
  'notifications_active_outlined': Icons.notifications_active_outlined,
  'palette_outlined': Icons.palette_outlined,
  'vibration_rounded': Icons.vibration_rounded,
  'fingerprint_rounded': Icons.fingerprint_rounded,
  'tablet_mac_rounded': Icons.tablet_mac_rounded,
  'storefront_outlined': Icons.storefront_outlined,
  'auto_awesome_rounded': Icons.auto_awesome_rounded,
  'timer_outlined': Icons.timer_outlined,
  'search_rounded': Icons.search_rounded,
  'grid_view_rounded': Icons.grid_view_rounded,
  'refresh_rounded': Icons.refresh_rounded,
  'warning_amber_rounded': Icons.warning_amber_rounded,
  'photo_library_outlined': Icons.photo_library_outlined,
  'tune_rounded': Icons.tune_rounded,
  'cloud_download_outlined': Icons.cloud_download_outlined,
  'cloud_off_rounded': Icons.cloud_off_rounded,
  'accessibility_new_rounded': Icons.accessibility_new_rounded,
  'translate_rounded': Icons.translate_rounded,
  'receipt_long_outlined': Icons.receipt_long_outlined,
  'animation_outlined': Icons.animation_outlined,
  'bug_report_outlined': Icons.bug_report_outlined,
  'bookmarks_outlined': Icons.bookmarks_outlined,
  'show_chart_rounded': Icons.show_chart_rounded,
};

/// Shows the update sheet.
///
/// [notes] defaults to everything newer than the last version seen; pass a
/// list explicitly to show it on demand from Settings.
Future<void> showWhatsNewSheet(
  BuildContext context, {
  required List<ReleaseNote> notes,
  bool offerMute = true,
}) {
  if (notes.isEmpty) return Future<void>.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Deliberately dismissible: an update note should never trap anyone.
    builder: (BuildContext context) =>
        WhatsNewSheet(notes: notes, offerMute: offerMute),
  );
}

class WhatsNewSheet extends ConsumerStatefulWidget {
  const WhatsNewSheet({required this.notes, super.key, this.offerMute = true});

  final List<ReleaseNote> notes;

  /// Whether to show the "don't show this again" option.
  final bool offerMute;

  @override
  ConsumerState<WhatsNewSheet> createState() => _WhatsNewSheetState();
}

class _WhatsNewSheetState extends ConsumerState<WhatsNewSheet> {
  bool _mute = false;

  Future<void> _dismiss() async {
    await ref.read(whatsNewProvider.notifier).markSeen(mute: _mute);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReleaseNote latest = widget.notes.first;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController controller) => Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Version ${latest.version}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(latest.headline, style: theme.textTheme.headlineSmall),
                if (widget.notes.length > 1) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Including everything from '
                    '${widget.notes.last.version} onwards.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
              children: <Widget>[
                for (int n = 0; n < widget.notes.length; n++) ...<Widget>[
                  if (n > 0) ...<Widget>[
                    const SizedBox(height: 22),
                    Text(
                      '${widget.notes[n].version} · '
                      '${widget.notes[n].headline}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  for (int i = 0; i < widget.notes[n].highlights.length; i++)
                    _HighlightRow(highlight: widget.notes[n].highlights[i])
                        .animate(delay: (i * 60).ms)
                        .fadeIn(duration: 260.ms)
                        .moveY(begin: 10, end: 0, curve: Curves.easeOutCubic),
                ],
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Column(
                children: <Widget>[
                  if (widget.offerMute)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      value: _mute,
                      onChanged: (bool? v) =>
                          setState(() => _mute = v ?? false),
                      title: Text(
                        'Don’t show this again',
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        'You can still find it in Settings → About',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  FilledButton(
                    onPressed: _dismiss,
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.highlight});

  final ReleaseHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              _icons[highlight.icon] ?? Icons.star_rounded,
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(highlight.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  highlight.body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
