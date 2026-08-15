// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get orderStatusProcessing => 'Processing';

  @override
  String get orderStatusShipped => 'Shipped';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusReturnRequested => 'Return requested';

  @override
  String get orderStatusRefunded => 'Refunded';

  @override
  String get returnReasonWrongSize => 'Wrong size or fit';

  @override
  String get returnReasonNotAsDescribed => 'Not as described';

  @override
  String get returnReasonDamaged => 'Arrived damaged';

  @override
  String get returnReasonWrongItem => 'Wrong item sent';

  @override
  String get returnReasonChangedMind => 'Changed my mind';

  @override
  String get returnReasonOther => 'Something else';

  @override
  String get authErrorEmailInvalid => 'Enter a valid email address';

  @override
  String get authErrorEmailTaken => 'An account already uses that email';

  @override
  String get authErrorNameRequired => 'Tell us your name';

  @override
  String get authErrorPasswordTooShort => 'Use at least 8 characters';

  @override
  String get authErrorPasswordTooCommon => 'That password is too easy to guess';

  @override
  String get authErrorPasswordMismatch => 'Those passwords don’t match';

  @override
  String get authErrorCredentialsWrong => 'Email or password is incorrect';

  @override
  String get deliveryStandardLabel => 'Standard';

  @override
  String get deliveryStandardBlurb => '3–5 business days';

  @override
  String get deliveryExpressLabel => 'Express';

  @override
  String get deliveryExpressBlurb => 'Next business day';

  @override
  String get deliveryPickupLabel => 'Collect in store';

  @override
  String get deliveryPickupBlurb => 'Ready in about 2 hours';

  @override
  String priceReducedFrom(String price, String was, int percent) {
    return '$price, reduced from $was, $percent% off';
  }

  @override
  String ratingOutOfFive(String rating) {
    return 'Rated $rating out of 5';
  }

  @override
  String ratingOutOfFiveWithReviews(String rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return 'Rated $rating out of 5 from $_temp0';
  }

  @override
  String get stockSoldOut => 'Sold out';

  @override
  String stockOnlyLeft(int count) {
    return 'Only $count left';
  }

  @override
  String get badgeNew => 'New';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get decreaseQuantity => 'Decrease quantity';

  @override
  String get increaseQuantity => 'Increase quantity';

  @override
  String get removeItem => 'Remove';

  @override
  String get saveToWishlist => 'Save to wishlist';

  @override
  String get removeFromWishlist => 'Remove from wishlist';

  @override
  String get productImage => 'Product image';

  @override
  String productImageOfCount(int index, int total) {
    return 'Product image $index of $total';
  }

  @override
  String get enlargeHint => 'enlarge';

  @override
  String get itemNoLongerAvailable => 'Item no longer available';

  @override
  String itemsNoLongerSold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are no longer sold',
      one: '1 item is no longer sold',
    );
    return '$_temp0';
  }

  @override
  String get catalogUnreachableMessage =>
      'Your items are safe — we just can’t reach the shop to look them up.';

  @override
  String get couldNotLoadBag => 'Couldn’t load your bag';

  @override
  String get couldNotLoadSaves => 'Couldn’t load your saves';

  @override
  String get retry => 'Retry';

  @override
  String get reorderAdded => 'Added back to your bag';

  @override
  String reorderNoneAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'None of these are available any more',
      one: 'That item is no longer available',
    );
    return '$_temp0';
  }

  @override
  String reorderPartial(int added, int skipped) {
    return '$added added back — $skipped no longer available';
  }

  @override
  String get viewBag => 'View bag';
}
