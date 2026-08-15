import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Order is accepted but not yet handed to the courier.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get orderStatusProcessing;

  /// Order is with the courier.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderStatusShipped;

  /// Order has arrived.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStatusDelivered;

  /// Order was cancelled before dispatch.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// A return has been filed but not yet refunded.
  ///
  /// In en, this message translates to:
  /// **'Return requested'**
  String get orderStatusReturnRequested;

  /// The refund has been paid back.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get orderStatusRefunded;

  /// Return reason. The shopper does not pay return postage for reasons that are the shop's fault; this one is not.
  ///
  /// In en, this message translates to:
  /// **'Wrong size or fit'**
  String get returnReasonWrongSize;

  /// Return reason, counted as the shop's fault.
  ///
  /// In en, this message translates to:
  /// **'Not as described'**
  String get returnReasonNotAsDescribed;

  /// Return reason, counted as the shop's fault.
  ///
  /// In en, this message translates to:
  /// **'Arrived damaged'**
  String get returnReasonDamaged;

  /// Return reason, counted as the shop's fault.
  ///
  /// In en, this message translates to:
  /// **'Wrong item sent'**
  String get returnReasonWrongItem;

  /// Return reason, not the shop's fault.
  ///
  /// In en, this message translates to:
  /// **'Changed my mind'**
  String get returnReasonChangedMind;

  /// Catch-all return reason.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get returnReasonOther;

  /// No description provided for @authErrorEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authErrorEmailInvalid;

  /// No description provided for @authErrorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'An account already uses that email'**
  String get authErrorEmailTaken;

  /// No description provided for @authErrorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Tell us your name'**
  String get authErrorNameRequired;

  /// No description provided for @authErrorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get authErrorPasswordTooShort;

  /// No description provided for @authErrorPasswordTooCommon.
  ///
  /// In en, this message translates to:
  /// **'That password is too easy to guess'**
  String get authErrorPasswordTooCommon;

  /// No description provided for @authErrorPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Those passwords don’t match'**
  String get authErrorPasswordMismatch;

  /// Deliberately vague. Saying which half was wrong tells an attacker whether an email is registered, so translations must not name the field either.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect'**
  String get authErrorCredentialsWrong;

  /// No description provided for @deliveryStandardLabel.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get deliveryStandardLabel;

  /// No description provided for @deliveryStandardBlurb.
  ///
  /// In en, this message translates to:
  /// **'3–5 business days'**
  String get deliveryStandardBlurb;

  /// No description provided for @deliveryExpressLabel.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get deliveryExpressLabel;

  /// No description provided for @deliveryExpressBlurb.
  ///
  /// In en, this message translates to:
  /// **'Next business day'**
  String get deliveryExpressBlurb;

  /// No description provided for @deliveryPickupLabel.
  ///
  /// In en, this message translates to:
  /// **'Collect in store'**
  String get deliveryPickupLabel;

  /// No description provided for @deliveryPickupBlurb.
  ///
  /// In en, this message translates to:
  /// **'Ready in about 2 hours'**
  String get deliveryPickupBlurb;

  /// Spoken form of a sale price. Drawn, the old price is struck through; read out, that formatting is gone, so the label has to say which number is which.
  ///
  /// In en, this message translates to:
  /// **'{price}, reduced from {was}, {percent}% off'**
  String priceReducedFrom(String price, String was, int percent);

  /// Spoken form of a star rating with no review count.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} out of 5'**
  String ratingOutOfFive(String rating);

  /// Spoken form of a star rating together with how many reviews it came from.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} out of 5 from {count, plural, =1{1 review} other{{count} reviews}}'**
  String ratingOutOfFiveWithReviews(String rating, int count);

  /// No description provided for @stockSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get stockSoldOut;

  /// No description provided for @stockOnlyLeft.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left'**
  String stockOnlyLeft(int count);

  /// No description provided for @badgeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get badgeNew;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @decreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get decreaseQuantity;

  /// No description provided for @increaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get increaseQuantity;

  /// Shown in place of a decrement when the line only has one left, so decrementing removes it.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeItem;

  /// No description provided for @saveToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Save to wishlist'**
  String get saveToWishlist;

  /// No description provided for @removeFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from wishlist'**
  String get removeFromWishlist;

  /// No description provided for @productImage.
  ///
  /// In en, this message translates to:
  /// **'Product image'**
  String get productImage;

  /// No description provided for @productImageOfCount.
  ///
  /// In en, this message translates to:
  /// **'Product image {index} of {total}'**
  String productImageOfCount(int index, int total);

  /// Screen-reader hint for what activating a gallery image does.
  ///
  /// In en, this message translates to:
  /// **'enlarge'**
  String get enlargeHint;

  /// Stands in for an order line whose product left the catalog before line snapshots existed.
  ///
  /// In en, this message translates to:
  /// **'Item no longer available'**
  String get itemNoLongerAvailable;

  /// Notice above the bag when some saved lines point at delisted products.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item is no longer sold} other{{count} items are no longer sold}}'**
  String itemsNoLongerSold(int count);

  /// No description provided for @catalogUnreachableMessage.
  ///
  /// In en, this message translates to:
  /// **'Your items are safe — we just can’t reach the shop to look them up.'**
  String get catalogUnreachableMessage;

  /// No description provided for @couldNotLoadBag.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your bag'**
  String get couldNotLoadBag;

  /// No description provided for @couldNotLoadSaves.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your saves'**
  String get couldNotLoadSaves;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reorderAdded.
  ///
  /// In en, this message translates to:
  /// **'Added back to your bag'**
  String get reorderAdded;

  /// No description provided for @reorderNoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{That item is no longer available} other{None of these are available any more}}'**
  String reorderNoneAvailable(int count);

  /// No description provided for @reorderPartial.
  ///
  /// In en, this message translates to:
  /// **'{added} added back — {skipped} no longer available'**
  String reorderPartial(int added, int skipped);

  /// No description provided for @viewBag.
  ///
  /// In en, this message translates to:
  /// **'View bag'**
  String get viewBag;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
