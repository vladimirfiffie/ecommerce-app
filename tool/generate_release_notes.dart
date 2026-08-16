// Prints the GitHub release body for a version, straight from the same data
// the in-app "What's new" sheet uses — so the two can't drift.
//
//   dart run tool/generate_release_notes.dart            # newest version
//   dart run tool/generate_release_notes.dart v0.2.0     # a specific one

import 'dart:io';

import 'package:ecommerce_app/core/release_notes.dart';

void main(List<String> args) {
  // Strip the leading v and any prerelease suffix: v0.4.1-beta.1 documents
  // the same release as 0.4.1. Without this the lookup misses and silently
  // falls back to the newest notes, which is wrong for a hotfix on an
  // older version.
  final String? requested = args.isEmpty
      ? null
      : args.first.replaceFirst(RegExp('^v'), '').split('-').first;

  final ReleaseNote note = kReleaseNotes.firstWhere(
    (ReleaseNote n) => requested == null || n.version == requested,
    orElse: () => kReleaseNotes.first,
  );

  // The workflow names artifacts after the tag, not the documented version,
  // so a prerelease ships `aster-v0.11.1-beta.1-arm64-v8a.apk`. Telling the
  // reader to grab `aster-v0.11.1-arm64-v8a.apk` sends them looking for a file
  // that isn't attached.
  final String tag = args.isEmpty ? 'v${note.version}' : args.first;

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
      'Grab `aster-$tag-arm64-v8a.apk` for most modern phones, or '
      'the `universal` APK if you are unsure of your device ABI. You will '
      'need to allow installs from unknown sources.',
    )
    ..writeln()
    ..writeln(
      'These APKs are **signed with Android debug keys** — fine for testing, '
      'not for distribution. Every build uses a freshly generated key, so no '
      'two releases share a signature: uninstall the old copy before '
      'installing this one, or Android reports "App not installed".',
    )
    ..writeln()
    ..writeln(
      'Products come from a public demo API and are cached on the device '
      'after the first load, so the first run needs a connection. No real '
      'payment is ever taken.',
    );

  stdout.write(out.toString());
}
