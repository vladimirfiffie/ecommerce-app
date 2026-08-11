import 'dart:io';

import 'package:ecommerce_app/core/release_notes.dart';
import 'package:ecommerce_app/state/whats_new_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('release notes data', () {
    test('the newest entry matches the version in pubspec', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      final RegExpMatch? match = RegExp(
        r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
        multiLine: true,
      ).firstMatch(pubspec);

      expect(match, isNotNull, reason: 'pubspec must declare a version');
      expect(
        currentReleaseVersion,
        match!.group(1),
        reason:
            'bump lib/core/release_notes.dart alongside pubspec, or the '
            'update sheet and the GitHub release body go stale',
      );
    });

    test('versions are unique and ordered newest first', () {
      final List<String> versions = kReleaseNotes
          .map((ReleaseNote n) => n.version)
          .toList();
      expect(versions.toSet(), hasLength(versions.length));

      for (int i = 1; i < versions.length; i++) {
        expect(
          compareVersions(versions[i - 1], versions[i]),
          greaterThan(0),
          reason: '${versions[i - 1]} should be newer than ${versions[i]}',
        );
      }
    });

    test('every note has content', () {
      for (final ReleaseNote note in kReleaseNotes) {
        expect(note.headline, isNotEmpty, reason: note.version);
        expect(note.highlights, isNotEmpty, reason: note.version);
        for (final ReleaseHighlight h in note.highlights) {
          expect(h.title, isNotEmpty);
          expect(h.body, isNotEmpty);
          expect(h.icon, isNotEmpty);
        }
      }
    });
  });

  group('version comparison', () {
    test('orders correctly', () {
      expect(compareVersions('1.0.0', '0.9.9'), greaterThan(0));
      expect(compareVersions('0.3.0', '0.10.0'), lessThan(0));
      expect(compareVersions('1.2.3', '1.2.3'), 0);
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('2.0', '1.9.9'), greaterThan(0));
    });

    test('a malformed segment counts as zero rather than throwing', () {
      expect(compareVersions('1.x.0', '1.0.0'), 0);
      expect(compareVersions('', '0.0.0'), 0);
    });
  });

  group('notes since a version', () {
    test('returns everything newer, newest first', () {
      final List<ReleaseNote> notes = releaseNotesSince('0.1.0');
      expect(notes.map((ReleaseNote n) => n.version), <String>[
        '0.3.0',
        '0.2.0',
      ]);
    });

    test('is empty when already current', () {
      expect(releaseNotesSince(currentReleaseVersion), isEmpty);
    });

    test('is empty for a fresh install', () {
      expect(releaseNotesSince(null), isEmpty);
    });
  });

  group('when the sheet shows', () {
    test('never on a first install — it records silently instead', () async {
      final ProviderContainer c = await testContainer();
      final WhatsNewNotifier n = c.read(whatsNewProvider.notifier);

      expect(c.read(whatsNewProvider).lastSeenVersion, isNull);
      expect(n.shouldShow, isFalse);

      await n.markSeen();
      expect(c.read(whatsNewProvider).lastSeenVersion, currentReleaseVersion);
      expect(n.shouldShow, isFalse);
    });

    test('after an upgrade from an older version', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: const <String, Object>{
          'whatsNew.lastSeenVersion': '0.1.0',
        },
      );
      final WhatsNewNotifier n = c.read(whatsNewProvider.notifier);

      expect(n.shouldShow, isTrue);
      expect(
        n.pending.map((ReleaseNote r) => r.version),
        <String>['0.3.0', '0.2.0'],
        reason: 'a skipped release must still be shown',
      );
    });

    test('not when the current version has already been seen', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: <String, Object>{
          'whatsNew.lastSeenVersion': currentReleaseVersion,
        },
      );
      expect(c.read(whatsNewProvider.notifier).shouldShow, isFalse);
    });

    test('not once muted, even on a later upgrade', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: const <String, Object>{
          'whatsNew.lastSeenVersion': '0.1.0',
          'whatsNew.muted': true,
        },
      );
      expect(c.read(whatsNewProvider.notifier).shouldShow, isFalse);
    });
  });

  group('dismissing', () {
    test('marks the version seen so it does not reappear', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: const <String, Object>{
          'whatsNew.lastSeenVersion': '0.1.0',
        },
      );
      final WhatsNewNotifier n = c.read(whatsNewProvider.notifier);
      expect(n.shouldShow, isTrue);

      await n.markSeen();
      expect(n.shouldShow, isFalse);
      expect(c.read(whatsNewProvider).muted, isFalse);
    });

    test('"don\'t show again" persists and survives a restart', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: const <String, Object>{
          'whatsNew.lastSeenVersion': '0.1.0',
        },
      );
      await c.read(whatsNewProvider.notifier).markSeen(mute: true);
      expect(c.read(whatsNewProvider).muted, isTrue);

      final ProviderContainer restarted = await testContainer(
        initialPrefs: const <String, Object>{
          'whatsNew.lastSeenVersion': '0.1.0',
          'whatsNew.muted': true,
        },
      );
      expect(restarted.read(whatsNewProvider).muted, isTrue);
      expect(restarted.read(whatsNewProvider.notifier).shouldShow, isFalse);
    });

    test('muting can be undone', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: const <String, Object>{
          'whatsNew.lastSeenVersion': '0.1.0',
          'whatsNew.muted': true,
        },
      );
      final WhatsNewNotifier n = c.read(whatsNewProvider.notifier);
      expect(n.shouldShow, isFalse);

      await n.unmute();
      expect(n.shouldShow, isTrue);
    });
  });
}
