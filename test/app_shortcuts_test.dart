import 'dart:io';

import 'package:ecommerce_app/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

/// The launcher shortcuts are declared in Android XML, which nothing in Dart
/// compiles against — so a route renamed in `Routes` would leave a shortcut
/// quietly opening the error page, on a surface almost nobody tests by hand.
///
/// These read the shipped XML and hold it to the routes the app actually has.
void main() {
  final File manifest = File('android/app/src/main/AndroidManifest.xml');
  final File shortcuts = File('android/app/src/main/res/xml/shortcuts.xml');
  final File strings = File('android/app/src/main/res/values/strings.xml');

  String read(File file) {
    expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
    return file.readAsStringSync();
  }

  /// Every `android:data` in the shortcuts file, in the order declared.
  List<String> declaredUrls() => RegExp(
    r'android:data="([^"]+)"',
  ).allMatches(read(shortcuts)).map((RegExpMatch m) => m.group(1)!).toList();

  test('the manifest points at the shortcuts file', () {
    expect(read(manifest), contains('android.app.shortcuts'));
    expect(read(manifest), contains('@xml/shortcuts'));
  });

  test('every shortcut aims at a route the app has', () {
    // Written as the app's own scheme so they arrive through the same
    // handling a shared link does, rather than naming an internal path.
    expect(declaredUrls(), <String>[
      'aster://orders',
      'aster://favorites',
      'aster://search',
      'aster://cart',
    ]);

    expect(
      declaredUrls().map((String url) => normalizeDeepLink(Uri.parse(url))),
      <String>[Routes.orders, Routes.favorites, Routes.search, Routes.cart],
    );
  });

  test('each one targets the activity that is actually installed', () {
    // A stale package name here doesn't fail the build — it fails silently,
    // as a shortcut that does nothing when tapped.
    final String gradle = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    final String? applicationId = RegExp(
      r'applicationId = "([^"]+)"',
    ).firstMatch(gradle)?.group(1);
    expect(applicationId, isNotNull);

    for (final RegExpMatch match in RegExp(
      r'android:targetPackage="([^"]+)"',
    ).allMatches(read(shortcuts))) {
      expect(match.group(1), applicationId);
    }
    expect(
      read(shortcuts),
      contains('android:targetClass="$applicationId.MainActivity"'),
    );
  });

  test('every label the launcher asks for exists', () {
    final String declared = read(strings);
    for (final RegExpMatch match in RegExp(
      r'@string/([A-Za-z_]+)',
    ).allMatches(read(shortcuts))) {
      expect(
        declared,
        contains('name="${match.group(1)}"'),
        reason: '${match.group(1)} is referenced but not defined',
      );
    }
  });

  test('every icon the launcher asks for exists', () {
    for (final RegExpMatch match in RegExp(
      r'@drawable/([A-Za-z_]+)',
    ).allMatches(read(shortcuts))) {
      expect(
        File(
          'android/app/src/main/res/drawable/${match.group(1)}.xml',
        ).existsSync(),
        isTrue,
        reason: '${match.group(1)}.xml is missing',
      );
    }
  });

  test('Android shows at most four, so there are at most four', () {
    expect(declaredUrls(), hasLength(lessThanOrEqualTo(4)));
  });
}
