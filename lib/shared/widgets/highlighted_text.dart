import 'package:material_ui/material_ui.dart';

/// A product name with the searched-for words picked out, so it's obvious
/// why a result matched — particularly when the terms are scattered through
/// the title rather than sitting together.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    required this.text,
    required this.query,
    super.key,
    this.style,
    this.maxLines = 1,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final List<String> terms = query.trim().toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((String t) => t.isEmpty);
    if (terms.isEmpty || text.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final String lower = text.toLowerCase();
    // Mark every character any term covers, then emit runs — simpler than
    // reconciling overlapping matches span by span.
    final List<bool> hit = List<bool>.filled(text.length, false);
    for (final String term in terms) {
      int from = 0;
      while (true) {
        final int at = lower.indexOf(term, from);
        if (at < 0) break;
        for (int i = at; i < at + term.length && i < hit.length; i++) {
          hit[i] = true;
        }
        from = at + term.length;
      }
    }

    final TextStyle base = style ?? const TextStyle();
    final TextStyle emphasis = base.copyWith(fontWeight: FontWeight.w800);
    final List<TextSpan> spans = <TextSpan>[];
    int start = 0;
    for (int i = 1; i <= text.length; i++) {
      if (i == text.length || hit[i] != hit[start]) {
        spans.add(
          TextSpan(
            text: text.substring(start, i),
            style: hit[start] ? emphasis : base,
          ),
        );
        start = i;
      }
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: base, children: spans),
    );
  }
}
