import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/state/addresses_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('recipient', () {
    test('needs an actual name', () {
      expect(AddressValidator.validateRecipient('Alex Rivera'), isNull);
      expect(AddressValidator.validateRecipient('Bo'), isNull);
      expect(AddressValidator.validateRecipient(''), isNotNull);
      expect(AddressValidator.validateRecipient('   '), isNotNull);
      expect(AddressValidator.validateRecipient('A'), isNotNull);
      expect(
        AddressValidator.validateRecipient('12345'),
        isNotNull,
        reason: 'a name with no letters in it is a typo every time',
      );
      expect(
        AddressValidator.validateRecipient('李明'),
        isNull,
        reason: 'a name is not required to be spelled in ASCII',
      );
    });

    test('rejects a pasted essay', () {
      expect(AddressValidator.validateRecipient('a' * 61), isNotNull);
      expect(AddressValidator.validateRecipient('a' * 60), isNull);
    });
  });

  group('street address', () {
    test('has to be long enough to be an address', () {
      expect(AddressValidator.validateLine1('218 Marlowe Street'), isNull);
      expect(AddressValidator.validateLine1(''), isNotNull);
      expect(AddressValidator.validateLine1('1 A'), isNotNull);
      expect(AddressValidator.validateLine1('a' * 121), isNotNull);
    });
  });

  group('city', () {
    test('needs letters, not just punctuation', () {
      expect(AddressValidator.validateCity('Portland, OR'), isNull);
      expect(AddressValidator.validateCity('-'), isNotNull);
      expect(AddressValidator.validateCity(''), isNotNull);
    });
  });

  group('postcode', () {
    test('a US ZIP is checked properly', () {
      String? zip(String v) =>
          AddressValidator.validatePostcode(v, country: 'United States');

      expect(zip('97205'), isNull);
      expect(zip('97205-1234'), isNull, reason: 'ZIP+4');
      expect(zip('9720'), isNotNull);
      expect(zip('972055'), isNotNull);
      expect(zip('ABCDE'), isNotNull);
      expect(zip(''), isNotNull);
    });

    test('the US is recognised however it is spelled', () {
      for (final String country in <String>[
        'US',
        'usa',
        'U.S.A.',
        ' United States ',
        'united states of america',
      ]) {
        expect(
          AddressValidator.validatePostcode('9720', country: country),
          isNotNull,
          reason: '$country should get the strict ZIP rule',
        );
      }
    });

    test('elsewhere only has to be plausible', () {
      String? code(String v) =>
          AddressValidator.validatePostcode(v, country: 'United Kingdom');

      // Formats differ in every country that has them, so this stays loose.
      expect(code('SW1A 1AA'), isNull);
      expect(code('75008'), isNull);
      expect(code('K1A 0B1'), isNull);
      expect(code(''), isNotNull);
      expect(code('!!'), isNotNull);
      expect(code('a' * 13), isNotNull);
    });
  });

  group('country', () {
    test('letters only, and not one of them', () {
      expect(AddressValidator.validateCountry('United States'), isNull);
      expect(AddressValidator.validateCountry("Côte d'Ivoire"), isNull);
      expect(AddressValidator.validateCountry('Guinea-Bissau'), isNull);
      expect(AddressValidator.validateCountry('Türkiye'), isNull);
      expect(AddressValidator.validateCountry('U'), isNotNull);
      expect(AddressValidator.validateCountry('12345'), isNotNull);
      expect(AddressValidator.validateCountry(''), isNotNull);
    });
  });

  group('label', () {
    test('is required and short', () {
      expect(AddressValidator.validateLabel('Home'), isNull);
      expect(AddressValidator.validateLabel(''), isNotNull);
      expect(AddressValidator.validateLabel('a' * 25), isNotNull);
    });
  });

  group('the address that ships with the app', () {
    test('passes every rule the form now enforces', () async {
      final ProviderContainer c = await testContainer();
      final Address seeded = c.read(addressesProvider).single;

      expect(AddressValidator.validateLabel(seeded.label), isNull);
      expect(AddressValidator.validateRecipient(seeded.recipient), isNull);
      expect(AddressValidator.validateLine1(seeded.line1), isNull);
      expect(AddressValidator.validateCity(seeded.city), isNull);
      expect(AddressValidator.validateCountry(seeded.country), isNull);
      expect(
        AddressValidator.validatePostcode(
          seeded.postcode,
          country: seeded.country,
        ),
        isNull,
      );
    });
  });
}
