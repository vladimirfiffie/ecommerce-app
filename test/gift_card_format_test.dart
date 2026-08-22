import 'package:ecommerce_app/data/models/credit_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the shape is read off the codes the shop issues', () {
    // ASTER-GIFT-nn: two fixed groups in front of the value.
    expect(GiftCardFormat.groupSizes, <int>[5, 4]);
  });

  group('typing a code', () {
    test('is punctuated and capitalised on the way in', () {
      expect(GiftCardFormat.format('astergift25'), 'ASTER-GIFT-25');
    });

    test('is punctuated before it is finished', () {
      expect(GiftCardFormat.format('aster'), 'ASTER');
      expect(GiftCardFormat.format('asterg'), 'ASTER-G');
      expect(GiftCardFormat.format('astergift'), 'ASTER-GIFT');
      expect(GiftCardFormat.format('astergift1'), 'ASTER-GIFT-1');
    });

    test('never leaves a dash with nothing after it', () {
      // Otherwise the field fights the shopper as they delete backwards.
      for (int i = 1; i <= 'ASTERGIFT100'.length; i++) {
        final String typed = GiftCardFormat.format(
          'ASTERGIFT100'.substring(0, i),
        );
        expect(typed.endsWith('-'), isFalse, reason: typed);
      }
    });

    test('a code pasted with its dashes already in survives', () {
      expect(GiftCardFormat.format('ASTER-GIFT-100'), 'ASTER-GIFT-100');
      expect(GiftCardFormat.format('aster-gift-50'), 'ASTER-GIFT-50');
    });

    test('junk and spacing are dropped rather than kept', () {
      expect(GiftCardFormat.format('  aster gift 25 '), 'ASTER-GIFT-25');
      expect(GiftCardFormat.format('aster_gift_25'), 'ASTER-GIFT-25');
    });

    test('every code the shop issues formats to itself', () {
      // The formatter and the accepted codes cannot drift apart.
      for (final String code in kGiftCards.keys) {
        expect(GiftCardFormat.format(code), code);
        expect(GiftCardFormat.format(code.toLowerCase()), code);
      }
    });
  });
}
