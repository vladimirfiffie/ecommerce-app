import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

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

  /// Delivery drop-off choice: the courier waits for someone to answer.
  ///
  /// In en, this message translates to:
  /// **'Hand it to me'**
  String get dropOffHandToMe;

  /// Delivery drop-off choice: the parcel is left on the doorstep.
  ///
  /// In en, this message translates to:
  /// **'Leave at my door'**
  String get dropOffAtDoor;

  /// Delivery drop-off choice. Spelling follows the app's American English elsewhere; the label is the shopper-facing wording.
  ///
  /// In en, this message translates to:
  /// **'Leave with a neighbour'**
  String get dropOffWithNeighbour;

  /// Delivery drop-off choice: a porch, a shed, behind a gate.
  ///
  /// In en, this message translates to:
  /// **'Leave in a safe place'**
  String get dropOffSafePlace;

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

  /// Sign-up/sign-in error: the email address is not a valid one.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authErrorEmailInvalid;

  /// Sign-up error: an account with that email already exists.
  ///
  /// In en, this message translates to:
  /// **'An account already uses that email'**
  String get authErrorEmailTaken;

  /// Sign-up error: the name field was left empty.
  ///
  /// In en, this message translates to:
  /// **'Tell us your name'**
  String get authErrorNameRequired;

  /// Sign-up error: the password is under the minimum length.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get authErrorPasswordTooShort;

  /// Sign-up error: the password is on the common-password list.
  ///
  /// In en, this message translates to:
  /// **'That password is too easy to guess'**
  String get authErrorPasswordTooCommon;

  /// Sign-up error: the two password fields differ.
  ///
  /// In en, this message translates to:
  /// **'Those passwords don’t match'**
  String get authErrorPasswordMismatch;

  /// Deliberately vague. Saying which half was wrong tells an attacker whether an email is registered, so translations must not name the field either.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect'**
  String get authErrorCredentialsWrong;

  /// Name of the cheapest delivery method.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get deliveryStandardLabel;

  /// How long standard delivery takes.
  ///
  /// In en, this message translates to:
  /// **'3–5 business days'**
  String get deliveryStandardBlurb;

  /// Name of the fastest paid delivery method.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get deliveryExpressLabel;

  /// How long express delivery takes.
  ///
  /// In en, this message translates to:
  /// **'Next business day'**
  String get deliveryExpressBlurb;

  /// Name of the collect-in-store method.
  ///
  /// In en, this message translates to:
  /// **'Collect in store'**
  String get deliveryPickupLabel;

  /// How long a click-and-collect order takes to be ready.
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

  /// Badge on a product with no stock left.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get stockSoldOut;

  /// Badge warning how few of a product remain.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left'**
  String stockOnlyLeft(int count);

  /// Badge on a recently added product.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get badgeNew;

  /// Label above the quantity stepper.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// Spoken label for the minus button on the quantity stepper.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get decreaseQuantity;

  /// Spoken label for the plus button on the quantity stepper.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get increaseQuantity;

  /// Shown in place of a decrement when the line only has one left, so decrementing removes it.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeItem;

  /// Spoken label for the heart when the product is not saved.
  ///
  /// In en, this message translates to:
  /// **'Save to wishlist'**
  String get saveToWishlist;

  /// Spoken label for the heart when the product is saved.
  ///
  /// In en, this message translates to:
  /// **'Remove from wishlist'**
  String get removeFromWishlist;

  /// Spoken label for a product photo with no position to give.
  ///
  /// In en, this message translates to:
  /// **'Product image'**
  String get productImage;

  /// Spoken label for one photo in a gallery, with its position.
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

  /// Shown when saved ids cannot be resolved because the shop is unreachable.
  ///
  /// In en, this message translates to:
  /// **'Your items are safe — we just can’t reach the shop to look them up.'**
  String get catalogUnreachableMessage;

  /// Title shown when the bag cannot be resolved against the catalog.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your bag'**
  String get couldNotLoadBag;

  /// Title shown when the wishlist cannot be resolved against the catalog.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your saves'**
  String get couldNotLoadSaves;

  /// Button that tries a failed load again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Shown after every line of a past order goes back in the bag.
  ///
  /// In en, this message translates to:
  /// **'Added back to your bag'**
  String get reorderAdded;

  /// Shown when nothing from a past order can be bought again.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{That item is no longer available} other{None of these are available any more}}'**
  String reorderNoneAvailable(int count);

  /// Shown when only some of a past order could go back in the bag.
  ///
  /// In en, this message translates to:
  /// **'{added} added back — {skipped} no longer available'**
  String reorderPartial(int added, int skipped);

  /// Button that opens the bag from a snackbar.
  ///
  /// In en, this message translates to:
  /// **'View bag'**
  String get viewBag;

  /// Title of the shopping bag tab.
  ///
  /// In en, this message translates to:
  /// **'Your bag'**
  String get bagTitle;

  /// Button that empties the bag.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get bagClear;

  /// Shown when nothing is in the bag.
  ///
  /// In en, this message translates to:
  /// **'Your bag is empty'**
  String get bagEmptyTitle;

  /// Body of the empty-bag state.
  ///
  /// In en, this message translates to:
  /// **'Once you add something you like, it’ll show up here.'**
  String get bagEmptyMessage;

  /// Button on the empty-bag state.
  ///
  /// In en, this message translates to:
  /// **'Start shopping'**
  String get bagEmptyAction;

  /// Confirmation dialog title before clearing the bag.
  ///
  /// In en, this message translates to:
  /// **'Empty your bag?'**
  String get bagConfirmClearTitle;

  /// Confirmation dialog body before clearing the bag.
  ///
  /// In en, this message translates to:
  /// **'This removes every item. It can’t be undone.'**
  String get bagConfirmClearMessage;

  /// Dismisses the empty-bag confirmation without clearing.
  ///
  /// In en, this message translates to:
  /// **'Keep them'**
  String get bagConfirmKeep;

  /// Confirms clearing the bag.
  ///
  /// In en, this message translates to:
  /// **'Empty bag'**
  String get bagConfirmEmpty;

  /// Snackbar after swiping an item out of the bag.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String bagRemovedItem(String name);

  /// Undoes the action a snackbar is reporting.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Moves a bag line into the saved-for-later list.
  ///
  /// In en, this message translates to:
  /// **'Save for later'**
  String get bagSaveForLater;

  /// Button that starts checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get bagCheckout;

  /// Heading of the set-aside items below the bag.
  ///
  /// In en, this message translates to:
  /// **'Saved for later'**
  String get savedForLaterTitle;

  /// Subheading counting the set-aside items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item waiting} other{{count} items waiting}}'**
  String savedForLaterCount(int count);

  /// Moves a set-aside item back into the bag.
  ///
  /// In en, this message translates to:
  /// **'Move to bag'**
  String get savedMoveToBag;

  /// Heading of the totals block in the bag.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get summaryTitle;

  /// Line in the totals block: the items before anything else.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get summarySubtotal;

  /// Line in the totals block for a promo code.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get summaryDiscount;

  /// Discount line naming the code that produced it.
  ///
  /// In en, this message translates to:
  /// **'Discount ({code})'**
  String summaryDiscountWithCode(String code);

  /// Line in the totals block for delivery cost.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get summaryShipping;

  /// Value shown where a charge would be, when there is none.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get summaryFree;

  /// Line in the totals block for the gift-wrapping fee.
  ///
  /// In en, this message translates to:
  /// **'Gift wrap'**
  String get summaryGiftWrap;

  /// Line in the totals block for tax.
  ///
  /// In en, this message translates to:
  /// **'Estimated tax'**
  String get summaryTax;

  /// The final amount, when nothing is being settled with credit.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get summaryTotal;

  /// What the order costs, shown above the credit line when credit is being used.
  ///
  /// In en, this message translates to:
  /// **'Order total'**
  String get summaryOrderTotal;

  /// Line in the totals block for store credit going onto this order.
  ///
  /// In en, this message translates to:
  /// **'Store credit'**
  String get summaryStoreCredit;

  /// What is left to charge the card after store credit.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get summaryToPay;

  /// Placeholder in the promo code field.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoHint;

  /// Button that applies a promo code.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get promoApply;

  /// Tooltip on the button that takes an applied promo code off.
  ///
  /// In en, this message translates to:
  /// **'Remove code'**
  String get promoRemove;

  /// Why a listed code cannot be applied yet.
  ///
  /// In en, this message translates to:
  /// **'Spend {amount} to use this'**
  String promoMinSpend(String amount);

  /// Names the code that saves the most on this bag.
  ///
  /// In en, this message translates to:
  /// **'Best code: {code}'**
  String promoBestCode(String code);

  /// What the suggested code is worth on the current bag.
  ///
  /// In en, this message translates to:
  /// **'Saves {amount} on this bag'**
  String promoSaves(String amount);

  /// Title of the checkout screen.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// Name of the first checkout step.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get checkoutStepShipping;

  /// Name of the second checkout step.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get checkoutStepPayment;

  /// Name of the third checkout step.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get checkoutStepReview;

  /// Returns to the previous checkout step.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get checkoutBack;

  /// Advances to the next checkout step.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get checkoutContinue;

  /// Label on the slide-to-confirm control that places the order.
  ///
  /// In en, this message translates to:
  /// **'Slide to pay {amount}'**
  String checkoutSlideToPay(String amount);

  /// Plain-button fallback where sliding is not available.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String checkoutPay(String amount);

  /// Shown when checkout is opened with an empty bag.
  ///
  /// In en, this message translates to:
  /// **'Nothing to check out'**
  String get checkoutEmptyTitle;

  /// Body of the empty-checkout state.
  ///
  /// In en, this message translates to:
  /// **'Your bag is empty.'**
  String get checkoutEmptyMessage;

  /// Button on the empty-checkout state.
  ///
  /// In en, this message translates to:
  /// **'Browse the shop'**
  String get checkoutEmptyAction;

  /// Reason shown in the OS biometric prompt before paying.
  ///
  /// In en, this message translates to:
  /// **'Confirm your identity to place this order'**
  String get checkoutBiometricReason;

  /// Shown when biometric verification fails or is dismissed.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled — not verified'**
  String get checkoutBiometricCancelled;

  /// Shown when the device cannot verify identity at all.
  ///
  /// In en, this message translates to:
  /// **'Biometrics unavailable — continuing without verification'**
  String get checkoutBiometricUnavailable;

  /// Named as the payment method when credit covered the whole order.
  ///
  /// In en, this message translates to:
  /// **'Store credit'**
  String get checkoutPaidByCredit;

  /// Fallback payment label when no specific card is selected.
  ///
  /// In en, this message translates to:
  /// **'Card on file'**
  String get checkoutCardOnFile;

  /// Heading above the saved addresses.
  ///
  /// In en, this message translates to:
  /// **'Ship to'**
  String get checkoutShipTo;

  /// Opens the new-address form.
  ///
  /// In en, this message translates to:
  /// **'Add a new address'**
  String get checkoutAddAddress;

  /// Heading above the delivery speed choices.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get checkoutDelivery;

  /// Heading of the delivery-instructions section.
  ///
  /// In en, this message translates to:
  /// **'When it arrives'**
  String get checkoutWhenItArrives;

  /// Label on the drop-off preference dropdown.
  ///
  /// In en, this message translates to:
  /// **'If you’re out'**
  String get checkoutIfYoureOut;

  /// Label on the free-text delivery note field.
  ///
  /// In en, this message translates to:
  /// **'Anything else for the courier (optional)'**
  String get checkoutCourierNote;

  /// Example of a delivery note.
  ///
  /// In en, this message translates to:
  /// **'Gate code 1234 — the blue door round the side'**
  String get checkoutCourierNoteHint;

  /// What happens with the default drop-off choice.
  ///
  /// In en, this message translates to:
  /// **'We’ll knock and wait. If nobody answers, it comes back with the courier.'**
  String get checkoutKnockAndWait;

  /// Liability note shown for any non-default drop-off choice.
  ///
  /// In en, this message translates to:
  /// **'A parcel left unattended is at your own risk once it’s been dropped off.'**
  String get checkoutUnattendedRisk;

  /// Heading above the saved cards.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get checkoutPayWith;

  /// Replaces the card list when credit settles the whole order.
  ///
  /// In en, this message translates to:
  /// **'Your store credit covers this order. No card will be charged.'**
  String get checkoutCreditCoversOrder;

  /// Heading when the wallet is empty at checkout.
  ///
  /// In en, this message translates to:
  /// **'No cards saved'**
  String get checkoutNoCards;

  /// Body when the wallet is empty at checkout.
  ///
  /// In en, this message translates to:
  /// **'Add one to continue. Only the last four digits are stored.'**
  String get checkoutNoCardsBody;

  /// Opens the add-card form.
  ///
  /// In en, this message translates to:
  /// **'Add a card'**
  String get checkoutAddCard;

  /// Opens the add-card form when cards already exist.
  ///
  /// In en, this message translates to:
  /// **'Add another card'**
  String get checkoutAddAnotherCard;

  /// Subtitle on a saved card that can no longer be used.
  ///
  /// In en, this message translates to:
  /// **'Expired {date}'**
  String checkoutCardExpired(String date);

  /// Subtitle on a usable saved card.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String checkoutCardExpires(String date);

  /// Warns that biometric verification is switched on.
  ///
  /// In en, this message translates to:
  /// **'You’ll be asked to verify before this order is placed.'**
  String get checkoutBiometricNotice;

  /// Says plainly that this build takes no real payment.
  ///
  /// In en, this message translates to:
  /// **'Demo checkout — no card is charged and no payment data is collected or stored.'**
  String get checkoutDemoNotice;

  /// Heading of the final checkout step.
  ///
  /// In en, this message translates to:
  /// **'Review your order'**
  String get checkoutReviewTitle;

  /// Label on the address row of the review step.
  ///
  /// In en, this message translates to:
  /// **'Shipping to'**
  String get checkoutShippingTo;

  /// Shown where the address would be, when none is chosen.
  ///
  /// In en, this message translates to:
  /// **'No address selected'**
  String get checkoutNoAddress;

  /// Label on the payment row of the review step.
  ///
  /// In en, this message translates to:
  /// **'Paying with'**
  String get checkoutPayingWith;

  /// Shown where the card would be, when none is chosen.
  ///
  /// In en, this message translates to:
  /// **'No card selected'**
  String get checkoutNoCard;

  /// Compact quantity on a review-step line.
  ///
  /// In en, this message translates to:
  /// **'Qty {count}'**
  String checkoutQuantityShort(int count);

  /// Counts what is being bought, in the checkout side pane.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String checkoutItemCount(int count);

  /// Switch that puts the balance towards this order.
  ///
  /// In en, this message translates to:
  /// **'Use store credit'**
  String get creditUseSwitch;

  /// Subtitle when credit settles the order outright.
  ///
  /// In en, this message translates to:
  /// **'{amount} covers this order — no card needed'**
  String creditCoversOrder(String amount);

  /// Subtitle when credit covers part of the order.
  ///
  /// In en, this message translates to:
  /// **'{applied} of {balance} goes on this order'**
  String creditPartOfOrder(String applied, String balance);

  /// Subtitle when the shopper has switched credit off.
  ///
  /// In en, this message translates to:
  /// **'{balance} available, kept for another time'**
  String creditKeptForLater(String balance);

  /// Switch that adds gift wrapping.
  ///
  /// In en, this message translates to:
  /// **'Gift wrap'**
  String get giftWrapTitle;

  /// What gift wrapping is and what it costs.
  ///
  /// In en, this message translates to:
  /// **'Wrapped in tissue and ribbon · {price}'**
  String giftWrapSubtitle(String price);

  /// Label on the gift message field.
  ///
  /// In en, this message translates to:
  /// **'Gift message (optional)'**
  String get giftMessageLabel;

  /// Example gift message.
  ///
  /// In en, this message translates to:
  /// **'Happy birthday!'**
  String get giftMessageHint;

  /// Reassurance shown once the order is marked as a gift.
  ///
  /// In en, this message translates to:
  /// **'Prices are left off the packing slip for gifts.'**
  String get giftPricesHidden;

  /// Says a promo code was chosen on the shopper's behalf.
  ///
  /// In en, this message translates to:
  /// **'{code} applied for you'**
  String promoAutoApplied(String code);

  /// Explains why that code was chosen.
  ///
  /// In en, this message translates to:
  /// **'The best code for this order — {description}'**
  String promoAutoAppliedBody(String description);

  /// Takes the auto-applied code back off.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get promoAutoAppliedRemove;

  /// Shown when a confirmation is opened for an order that does not exist.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get confirmationNotFoundTitle;

  /// Body of the order-not-found state.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find order {id}.'**
  String confirmationNotFoundMessage(String id);

  /// Button on the order-not-found state.
  ///
  /// In en, this message translates to:
  /// **'Back to shop'**
  String get confirmationBackToShop;

  /// Headline of the order confirmation screen.
  ///
  /// In en, this message translates to:
  /// **'Order confirmed'**
  String get confirmationTitle;

  /// Subhead of the order confirmation screen.
  ///
  /// In en, this message translates to:
  /// **'Thanks! We’re getting order {id} ready to ship.'**
  String confirmationThanks(String id);

  /// Label on the item-count row of the confirmation summary.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get confirmationItems;

  /// Label on the total row of the confirmation summary.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get confirmationTotalPaid;

  /// Label on the estimated-delivery row of the confirmation summary.
  ///
  /// In en, this message translates to:
  /// **'Arrives by'**
  String get confirmationArrivesBy;

  /// Label on the payment row of the confirmation summary.
  ///
  /// In en, this message translates to:
  /// **'Paid with'**
  String get confirmationPaidWith;

  /// Opens the order detail screen.
  ///
  /// In en, this message translates to:
  /// **'Track this order'**
  String get confirmationTrack;

  /// Returns to the home tab.
  ///
  /// In en, this message translates to:
  /// **'Keep shopping'**
  String get confirmationKeepShopping;

  /// Confirmation dialog title for cancelling inside the change window.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get confirmationCancelTitle;

  /// Confirmation dialog body for cancelling inside the change window.
  ///
  /// In en, this message translates to:
  /// **'Nothing was charged, and the items go back to your bag.'**
  String get confirmationCancelMessage;

  /// Confirms cancelling the order.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get confirmationCancelConfirm;

  /// Shown after a successful cancellation.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get confirmationCancelled;

  /// Shown when the change window closed before the tap landed.
  ///
  /// In en, this message translates to:
  /// **'Too late to cancel — track it instead'**
  String get confirmationTooLateToCancel;

  /// Shown after redirecting an order inside the change window.
  ///
  /// In en, this message translates to:
  /// **'Sending it to {label} instead'**
  String confirmationAddressChanged(String label);

  /// Shown when the change window closed before the address change landed.
  ///
  /// In en, this message translates to:
  /// **'Too late to change that'**
  String get confirmationTooLateToChange;

  /// Opens the address picker inside the change window.
  ///
  /// In en, this message translates to:
  /// **'Change address'**
  String get confirmationChangeAddress;

  /// Title of the orders screen.
  ///
  /// In en, this message translates to:
  /// **'Your orders'**
  String get ordersTitle;

  /// Shown when nothing has been ordered.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get ordersEmptyTitle;

  /// Body of the no-orders state.
  ///
  /// In en, this message translates to:
  /// **'When you place an order it’ll appear here with its delivery status.'**
  String get ordersEmptyMessage;

  /// Button on the no-orders state.
  ///
  /// In en, this message translates to:
  /// **'Browse the shop'**
  String get ordersEmptyAction;

  /// Placeholder in the tablet detail pane before an order is picked.
  ///
  /// In en, this message translates to:
  /// **'Choose an order to see its details.'**
  String get ordersPickOne;

  /// Counts the lines on an order.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String orderItemCount(int count);

  /// Shown when an order detail screen is opened for an order that does not exist.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFoundTitle;

  /// Body of the order-not-found state.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find order {id}.'**
  String orderNotFoundMessage(String id);

  /// Button back to the orders list.
  ///
  /// In en, this message translates to:
  /// **'All orders'**
  String get orderAllOrders;

  /// Heading above what was bought.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get orderItems;

  /// What the card was charged after store credit came off.
  ///
  /// In en, this message translates to:
  /// **'Charged'**
  String get orderCharged;

  /// Heading above the shipping address and instructions.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get orderDelivery;

  /// Heading above the gift wrapping and message.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get orderGift;

  /// Says the order was gift wrapped.
  ///
  /// In en, this message translates to:
  /// **'Gift wrapped'**
  String get orderGiftWrapped;

  /// Heading above how the order was paid for.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get orderPayment;

  /// Button that cancels an order that has not shipped.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order'**
  String get orderCancelAction;

  /// Button that starts a return, with how long the window has left.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Return items · 1 day left} other{Return items · {days} days left}}'**
  String orderReturnAction(int days);

  /// Opens the receipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get orderViewReceipt;

  /// Puts the order back in the bag at today’s prices.
  ///
  /// In en, this message translates to:
  /// **'Buy these again'**
  String get orderBuyAgain;

  /// Confirms cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get orderCancelConfirm;

  /// Dismisses the cancel confirmation.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get orderCancelKeep;

  /// Shown after a successful cancellation.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// Shown when the order shipped before the cancel landed.
  ///
  /// In en, this message translates to:
  /// **'Too late to cancel — it has already shipped'**
  String get orderTooLateToCancel;

  /// Replaces the delivery tracker on a refunded order.
  ///
  /// In en, this message translates to:
  /// **'This order was refunded. Nothing is on its way.'**
  String get orderRefundedNothingComing;

  /// Replaces the delivery tracker on a cancelled order.
  ///
  /// In en, this message translates to:
  /// **'This order was cancelled and won’t be delivered.'**
  String get orderCancelledNothingComing;

  /// Tracker caption while a return is open.
  ///
  /// In en, this message translates to:
  /// **'Delivered · return in progress'**
  String get orderDeliveredReturnInProgress;

  /// Tracker caption with the estimated delivery date.
  ///
  /// In en, this message translates to:
  /// **'Arriving by {date}'**
  String orderArrivingBy(String date);

  /// Heading of the return block before the refund lands.
  ///
  /// In en, this message translates to:
  /// **'Return in progress'**
  String get orderReturnInProgress;

  /// Where a refund went when the order was part-paid with credit. Follows the return reason in a sentence.
  ///
  /// In en, this message translates to:
  /// **'refunded to your card and store credit'**
  String get orderRefundedToCardAndCredit;

  /// Where a refund went. Follows the return reason in a sentence.
  ///
  /// In en, this message translates to:
  /// **'refunded to {method}'**
  String orderRefundedTo(String method);

  /// When a filed refund is due. Follows the return reason in a sentence.
  ///
  /// In en, this message translates to:
  /// **'expect your refund by {date}'**
  String orderRefundExpectedBy(String date);

  /// Cancels a return that has not been refunded yet.
  ///
  /// In en, this message translates to:
  /// **'Withdraw return'**
  String get orderWithdrawReturn;

  /// Title of the return request screen.
  ///
  /// In en, this message translates to:
  /// **'Return items'**
  String get returnTitle;

  /// Title of the return screen when the order could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnTitleShort;

  /// Shown when the return window closed before the request landed.
  ///
  /// In en, this message translates to:
  /// **'This order can no longer be returned'**
  String get returnNoLongerPossible;

  /// Shown after a return is filed, with the refund amount.
  ///
  /// In en, this message translates to:
  /// **'Return started · {amount}'**
  String returnStarted(String amount);

  /// Shown when the order behind a return cannot be found.
  ///
  /// In en, this message translates to:
  /// **'Nothing to return'**
  String get returnNothingTitle;

  /// Body of the nothing-to-return state.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find that order.'**
  String get returnNothingMessage;

  /// Deselects every line.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get returnClearSelection;

  /// Selects every line.
  ///
  /// In en, this message translates to:
  /// **'Select everything'**
  String get returnSelectEverything;

  /// Heading above the return reasons.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get returnWhy;

  /// Label on the free-text return note.
  ///
  /// In en, this message translates to:
  /// **'Anything else? (optional)'**
  String get returnNoteLabel;

  /// Disabled submit button, when nothing is selected.
  ///
  /// In en, this message translates to:
  /// **'Choose items to return'**
  String get returnChooseItems;

  /// Submit button, with what would come back.
  ///
  /// In en, this message translates to:
  /// **'Request {amount} refund'**
  String returnRequestRefund(String amount);

  /// Heading of the refund breakdown.
  ///
  /// In en, this message translates to:
  /// **'Refund estimate'**
  String get returnEstimate;

  /// The total that would be refunded.
  ///
  /// In en, this message translates to:
  /// **'Back on your card'**
  String get returnBackOnCard;

  /// Shown for return reasons that are the shop’s fault.
  ///
  /// In en, this message translates to:
  /// **'We got this wrong, so return postage is on us.'**
  String get returnPostageOnUs;

  /// Title of the receipt screen.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// Shown when the order behind a receipt cannot be found.
  ///
  /// In en, this message translates to:
  /// **'Receipt unavailable'**
  String get receiptUnavailableTitle;

  /// Tooltip on the button that copies the receipt text.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get receiptCopy;

  /// Shown after the receipt is copied.
  ///
  /// In en, this message translates to:
  /// **'Receipt copied'**
  String get receiptCopied;

  /// Tooltip on the share button.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get receiptShare;

  /// Subject line when a receipt is shared.
  ///
  /// In en, this message translates to:
  /// **'Aster receipt {id}'**
  String receiptShareSubject(String id);

  /// Tooltip on the button that renders the receipt as a PDF.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get receiptExportPdf;

  /// First line of the plain-text receipt. Kept in capitals.
  ///
  /// In en, this message translates to:
  /// **'ASTER — RECEIPT'**
  String get receiptHeading;

  /// Names the order on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Order {id}'**
  String receiptOrderLine(String id);

  /// Row label for the order status on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get receiptStatus;

  /// Section heading on the plain-text receipt. Kept in capitals.
  ///
  /// In en, this message translates to:
  /// **'ITEMS'**
  String get receiptItemsHeading;

  /// Total row on the plain-text receipt. Kept in capitals.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get receiptTotalCaps;

  /// What the card was charged, on the plain-text receipt. Kept in capitals.
  ///
  /// In en, this message translates to:
  /// **'CHARGED'**
  String get receiptChargedCaps;

  /// Row label for the delivery method on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get receiptDeliveryLabel;

  /// Row label for the address on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Ship to'**
  String get receiptShipTo;

  /// Row label for the payment method on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Paid with'**
  String get receiptPaidWith;

  /// Row label for the delivery instructions on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get receiptCourier;

  /// Row label for the delivery note on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get receiptNote;

  /// Row label for the gift message on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get receiptGiftMessage;

  /// Return summary on the plain-text receipt.
  ///
  /// In en, this message translates to:
  /// **'RETURN: {reason} — refund {amount}'**
  String receiptReturnLine(String reason, String amount);

  /// Footer on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Aster is a demo storefront. No payment was taken.'**
  String get receiptDemoFooter;

  /// Shown in the refund estimate before anything is selected.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one item to see what comes back.'**
  String get returnPickSomething;

  /// Refund breakdown row: the value of what is going back.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get returnLineItems;

  /// Refund breakdown row: outbound postage, refunded only on a full return.
  ///
  /// In en, this message translates to:
  /// **'Original shipping'**
  String get returnLineOriginalShipping;

  /// Refund breakdown row: tax on what is being refunded.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get returnLineTax;

  /// Shown for return reasons that are not the shop’s fault.
  ///
  /// In en, this message translates to:
  /// **'Return postage is deducted from your refund unless the item arrived damaged or incorrect.'**
  String get returnPostageDeducted;

  /// Row label naming the order on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get receiptOrder;

  /// Row label for when the order was placed.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get receiptPlaced;

  /// Row label for the address on the PDF receipt.
  ///
  /// In en, this message translates to:
  /// **'Ships to'**
  String get receiptShipsTo;

  /// Row label for the return reason on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get receiptReturn;

  /// Row label for the refunded amount on the receipt.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get receiptRefund;

  /// Column header for quantity in the PDF receipt table.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get receiptQty;

  /// Column header for the product in the PDF receipt table.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get receiptItem;

  /// Column header for a line total in the PDF receipt table.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get receiptLineTotal;

  /// Document title of the exported PDF.
  ///
  /// In en, this message translates to:
  /// **'Aster receipt {id}'**
  String receiptPdfTitle(String id);

  /// Checkout button with the order total on it.
  ///
  /// In en, this message translates to:
  /// **'Checkout · {amount}'**
  String bagCheckoutWithTotal(String amount);

  /// How much more to spend before standard delivery is free.
  ///
  /// In en, this message translates to:
  /// **'Add {amount} for free shipping'**
  String bagFreeShippingNudge(String amount);

  /// Countdown on the confirmation screen, while the order can still be undone.
  ///
  /// In en, this message translates to:
  /// **'Changed your mind? {time} left'**
  String changeWindowLeft(String time);

  /// What the change window allows.
  ///
  /// In en, this message translates to:
  /// **'Until then this order can be cancelled or sent somewhere else.'**
  String get changeWindowBody;

  /// Confirmation body before cancelling an order from its detail screen.
  ///
  /// In en, this message translates to:
  /// **'It hasn’t shipped yet, so it can still be stopped. This can’t be undone.'**
  String get orderCancelMessage;

  /// When the order was placed, on its detail screen.
  ///
  /// In en, this message translates to:
  /// **'Placed {date}'**
  String orderPlacedOn(String date);

  /// Heading above the lines that can be returned.
  ///
  /// In en, this message translates to:
  /// **'What are you sending back?'**
  String get returnWhatHeading;

  /// How long the return window has left.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day left to return this order.} other{{days} days left to return this order.}}'**
  String returnDaysLeft(int days);

  /// Name the shopper gives an address, like Home or Work.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get addressLabelField;

  /// Who the parcel is addressed to.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get addressFullName;

  /// Street line of an address.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get addressStreet;

  /// City line of an address.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get addressCity;

  /// Country line of an address.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get addressCountry;

  /// Button that saves the address form.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get addressSave;

  /// Postal code field, labelled the way the chosen country labels it. This is the United States form.
  ///
  /// In en, this message translates to:
  /// **'ZIP'**
  String get addressPostcodeUs;

  /// Postal code field for countries that do not call it a ZIP.
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get addressPostcodeOther;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'es':
      return AppL10nEs();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
