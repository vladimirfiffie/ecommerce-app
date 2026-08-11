// Prints the GitHub release body for a version, straight from the same data
// the in-app "What's new" sheet uses — so the two can't drift.
//
//   dart run tool/generate_release_notes.dart            # newest version
//   dart run tool/generate_release_notes.dart v0.2.0     # a specific one

import 'dart:io';

import 'package:ecommerce_app/core/release_notes.dart';

void main(List<String> args) {
  final String? requested = args.isEmpty
      ? null
      : args.first.replaceFirst(RegExp('^v'), '');

  final ReleaseNote note = kReleaseNotes.firstWhere(
    (ReleaseNote n) => requested == null || n.version == requested,
    orElse: () => kReleaseNotes.first,
  );

  final StringBuffer out = StringBuffer()
    ..writeln('## ${note.headline}')
    ..writeln();

  for (final ReleaseHighlight h in note.highlights) {
    out.writeln('- **${h.title}** — ${h.body}');
  }

  out
    ..writeln()
    ..writeln('### Installing')
    ..writeln()
    ..writeln(
      'Grab `nova-v${note.version}-arm64-v8a.apk` for most modern phones, or '
      'the `universal` APK if you are unsure of your device ABI. You will '
      'need to allow installs from unknown sources.',
    )
    ..writeln()
    ..writeln(
      'These APKs are **signed with Android debug keys** — fine for testing, '
      'not for distribution. Product data ships inside the app; imagery is '
      'fetched from a public CDN, so the first load needs a connection. '
      'No real payment is ever taken.',
    );

  stdout.write(out.toString());
}
