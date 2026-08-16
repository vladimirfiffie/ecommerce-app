import 'package:ecommerce_app/state/fit_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(configureTestEnvironment);

  const List<String> fullRun = <String>['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  FitProfile person(
    int cm,
    int kg, [
    FitPreference fit = FitPreference.regular,
  ]) => FitProfile(heightCm: cm, weightKg: kg, preference: fit);

  group('the recommendation', () {
    test('an average build lands mid-run', () {
      // 1.78m, 75kg — a body mass index of about 23.7.
      expect(recommendedSize(person(178, 75), fullRun), 'M');
    });

    test('a lighter build sizes down and a heavier one up', () {
      // 1.80m/65kg is a body mass index of 20.1; 1.70m/95kg is 32.9.
      expect(recommendedSize(person(180, 65), fullRun), 'S');
      expect(recommendedSize(person(170, 95), fullRun), 'XXL');
    });

    test('the fit preference shifts it one either way', () {
      expect(
        recommendedSize(person(178, 75, FitPreference.snug), fullRun),
        'S',
      );
      expect(
        recommendedSize(person(178, 75, FitPreference.relaxed), fullRun),
        'L',
      );
    });

    test('it never suggests a size the product does not stock', () {
      const List<String> shortRun = <String>['M', 'L'];
      final String? small = recommendedSize(person(185, 55), shortRun);

      expect(shortRun, contains(small));
      expect(small, 'M', reason: 'the nearest stocked size to XS');
    });

    test('half an answer gets no suggestion', () {
      expect(recommendedSize(const FitProfile(heightCm: 178), fullRun), isNull);
      expect(recommendedSize(const FitProfile(), fullRun), isNull);
    });

    test('shoes are left alone', () {
      expect(
        recommendedSize(person(178, 75), <String>['8', '9', '10']),
        isNull,
        reason: 'body mass says nothing about shoe size',
      );
    });

    test('it stays inside the run at both ends', () {
      expect(
        recommendedSize(person(200, 45, FitPreference.snug), fullRun),
        'XS',
      );
      expect(
        recommendedSize(person(150, 120, FitPreference.relaxed), fullRun),
        'XXL',
      );
    });
  });

  group('the profile', () {
    test('is remembered for the next product', () async {
      final ProviderContainer c = await testContainer();
      await c
          .read(fitProfileProvider.notifier)
          .save(person(178, 75, FitPreference.relaxed));

      final ProviderContainer relaunched = await testContainer(
        initialPrefs: <String, Object>{
          'fit.heightCm': 178,
          'fit.weightKg': 75,
          'fit.preference': 'relaxed',
        },
      );

      final FitProfile saved = relaunched.read(fitProfileProvider);
      expect(saved.heightCm, 178);
      expect(saved.weightKg, 75);
      expect(saved.preference, FitPreference.relaxed);
      expect(saved.isComplete, isTrue);
    });

    test(
      'an unknown stored preference falls back rather than throwing',
      () async {
        final ProviderContainer c = await testContainer(
          initialPrefs: <String, Object>{'fit.preference': 'baggy'},
        );
        expect(c.read(fitProfileProvider).preference, FitPreference.regular);
      },
    );
  });
}
