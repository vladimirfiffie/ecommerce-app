import 'package:ecommerce_app/data/models/address_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the icon an address is found by', () {
    test('follows the offered labels', () {
      expect(AddressLabel.iconFor('Home'), Icons.home_rounded);
      expect(AddressLabel.iconFor('Work'), Icons.business_rounded);
      expect(AddressLabel.iconFor('School'), Icons.school_rounded);
    });

    test('does not care about case or stray spacing', () {
      // The label is free text, so it arrives however it was typed.
      expect(AddressLabel.iconFor('  home '), Icons.home_rounded);
      expect(AddressLabel.iconFor('WORK'), Icons.business_rounded);
    });

    test('falls back to a pin for a name nobody anticipated', () {
      // "The cabin" is a real address and no list will ever have it.
      expect(AddressLabel.iconFor('The cabin'), Icons.place_rounded);
      expect(AddressLabel.iconFor(''), Icons.place_rounded);
    });

    test('every offered label has its own icon', () {
      final Set<IconData> icons = AddressLabel.values
          .map((AddressLabel l) => l.icon)
          .toSet();
      expect(icons, hasLength(AddressLabel.values.length));
    });
  });

  group('knowing whether a label was offered', () {
    test('recognises the ones it offers', () {
      expect(AddressLabel.isPreset('Gym'), isTrue);
      expect(AddressLabel.isPreset('family'), isTrue);
    });

    test('and does not claim one it did not', () {
      expect(AddressLabel.isPreset('The cabin'), isFalse);
    });
  });
}
