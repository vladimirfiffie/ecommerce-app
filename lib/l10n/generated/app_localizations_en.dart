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
  String get dropOffHandToMe => 'Hand it to me';

  @override
  String get dropOffAtDoor => 'Leave at my door';

  @override
  String get dropOffWithNeighbour => 'Leave with a neighbour';

  @override
  String get dropOffSafePlace => 'Leave in a safe place';

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

  @override
  String get bagTitle => 'Your bag';

  @override
  String get bagClear => 'Clear';

  @override
  String get bagEmptyTitle => 'Your bag is empty';

  @override
  String get bagEmptyMessage =>
      'Once you add something you like, it’ll show up here.';

  @override
  String get bagEmptyAction => 'Start shopping';

  @override
  String get bagConfirmClearTitle => 'Empty your bag?';

  @override
  String get bagConfirmClearMessage =>
      'This removes every item. It can’t be undone.';

  @override
  String get bagConfirmKeep => 'Keep them';

  @override
  String get bagConfirmEmpty => 'Empty bag';

  @override
  String bagRemovedItem(String name) {
    return 'Removed $name';
  }

  @override
  String get undo => 'Undo';

  @override
  String get bagSaveForLater => 'Save for later';

  @override
  String get bagCheckout => 'Checkout';

  @override
  String get savedForLaterTitle => 'Saved for later';

  @override
  String savedForLaterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items waiting',
      one: '1 item waiting',
    );
    return '$_temp0';
  }

  @override
  String get savedMoveToBag => 'Move to bag';

  @override
  String get summaryTitle => 'Order summary';

  @override
  String get summarySubtotal => 'Subtotal';

  @override
  String get summaryDiscount => 'Discount';

  @override
  String summaryDiscountWithCode(String code) {
    return 'Discount ($code)';
  }

  @override
  String get summaryShipping => 'Shipping';

  @override
  String get summaryFree => 'Free';

  @override
  String get summaryGiftWrap => 'Gift wrap';

  @override
  String get summaryTax => 'Estimated tax';

  @override
  String get summaryTotal => 'Total';

  @override
  String get summaryOrderTotal => 'Order total';

  @override
  String get summaryStoreCredit => 'Store credit';

  @override
  String get summaryToPay => 'To pay';

  @override
  String get promoHint => 'Promo code';

  @override
  String get promoApply => 'Apply';

  @override
  String get promoRemove => 'Remove code';

  @override
  String promoMinSpend(String amount) {
    return 'Spend $amount to use this';
  }

  @override
  String promoBestCode(String code) {
    return 'Best code: $code';
  }

  @override
  String promoSaves(String amount) {
    return 'Saves $amount on this bag';
  }

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutStepShipping => 'Shipping';

  @override
  String get checkoutStepPayment => 'Payment';

  @override
  String get checkoutStepReview => 'Review';

  @override
  String get checkoutBack => 'Back';

  @override
  String get checkoutContinue => 'Continue';

  @override
  String checkoutSlideToPay(String amount) {
    return 'Slide to pay $amount';
  }

  @override
  String checkoutPay(String amount) {
    return 'Pay $amount';
  }

  @override
  String get checkoutEmptyTitle => 'Nothing to check out';

  @override
  String get checkoutEmptyMessage => 'Your bag is empty.';

  @override
  String get checkoutEmptyAction => 'Browse the shop';

  @override
  String get checkoutBiometricReason =>
      'Confirm your identity to place this order';

  @override
  String get checkoutBiometricCancelled => 'Payment cancelled — not verified';

  @override
  String get checkoutBiometricUnavailable =>
      'Biometrics unavailable — continuing without verification';

  @override
  String get checkoutPaidByCredit => 'Store credit';

  @override
  String get checkoutCardOnFile => 'Card on file';

  @override
  String get checkoutShipTo => 'Ship to';

  @override
  String get checkoutAddAddress => 'Add a new address';

  @override
  String get checkoutDelivery => 'Delivery';

  @override
  String get checkoutWhenItArrives => 'When it arrives';

  @override
  String get checkoutIfYoureOut => 'If you’re out';

  @override
  String get checkoutCourierNote => 'Anything else for the courier (optional)';

  @override
  String get checkoutCourierNoteHint =>
      'Gate code 1234 — the blue door round the side';

  @override
  String get checkoutKnockAndWait =>
      'We’ll knock and wait. If nobody answers, it comes back with the courier.';

  @override
  String get checkoutUnattendedRisk =>
      'A parcel left unattended is at your own risk once it’s been dropped off.';

  @override
  String get checkoutPayWith => 'Pay with';

  @override
  String get checkoutCreditCoversOrder =>
      'Your store credit covers this order. No card will be charged.';

  @override
  String get checkoutNoCards => 'No cards saved';

  @override
  String get checkoutNoCardsBody =>
      'Add one to continue. Only the last four digits are stored.';

  @override
  String get checkoutAddCard => 'Add a card';

  @override
  String get checkoutAddAnotherCard => 'Add another card';

  @override
  String checkoutCardExpired(String date) {
    return 'Expired $date';
  }

  @override
  String checkoutCardExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get checkoutBiometricNotice =>
      'You’ll be asked to verify before this order is placed.';

  @override
  String get checkoutDemoNotice =>
      'Demo checkout — no card is charged and no payment data is collected or stored.';

  @override
  String get checkoutReviewTitle => 'Review your order';

  @override
  String get checkoutShippingTo => 'Shipping to';

  @override
  String get checkoutNoAddress => 'No address selected';

  @override
  String get checkoutPayingWith => 'Paying with';

  @override
  String get checkoutNoCard => 'No card selected';

  @override
  String checkoutQuantityShort(int count) {
    return 'Qty $count';
  }

  @override
  String checkoutItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get creditUseSwitch => 'Use store credit';

  @override
  String creditCoversOrder(String amount) {
    return '$amount covers this order — no card needed';
  }

  @override
  String creditPartOfOrder(String applied, String balance) {
    return '$applied of $balance goes on this order';
  }

  @override
  String creditKeptForLater(String balance) {
    return '$balance available, kept for another time';
  }

  @override
  String get giftWrapTitle => 'Gift wrap';

  @override
  String giftWrapSubtitle(String price) {
    return 'Wrapped in tissue and ribbon · $price';
  }

  @override
  String get giftMessageLabel => 'Gift message (optional)';

  @override
  String get giftMessageHint => 'Happy birthday!';

  @override
  String get giftPricesHidden =>
      'Prices are left off the packing slip for gifts.';

  @override
  String promoAutoApplied(String code) {
    return '$code applied for you';
  }

  @override
  String promoAutoAppliedBody(String description) {
    return 'The best code for this order — $description';
  }

  @override
  String get promoAutoAppliedRemove => 'Remove';

  @override
  String get confirmationNotFoundTitle => 'Order not found';

  @override
  String confirmationNotFoundMessage(String id) {
    return 'We couldn’t find order $id.';
  }

  @override
  String get confirmationBackToShop => 'Back to shop';

  @override
  String get confirmationTitle => 'Order confirmed';

  @override
  String confirmationThanks(String id) {
    return 'Thanks! We’re getting order $id ready to ship.';
  }

  @override
  String get confirmationItems => 'Items';

  @override
  String get confirmationTotalPaid => 'Total paid';

  @override
  String get confirmationArrivesBy => 'Arrives by';

  @override
  String get confirmationPaidWith => 'Paid with';

  @override
  String get confirmationTrack => 'Track this order';

  @override
  String get confirmationKeepShopping => 'Keep shopping';

  @override
  String get confirmationCancelTitle => 'Cancel this order?';

  @override
  String get confirmationCancelMessage =>
      'Nothing was charged, and the items go back to your bag.';

  @override
  String get confirmationCancelConfirm => 'Cancel order';

  @override
  String get confirmationCancelled => 'Order cancelled';

  @override
  String get confirmationTooLateToCancel =>
      'Too late to cancel — track it instead';

  @override
  String confirmationAddressChanged(String label) {
    return 'Sending it to $label instead';
  }

  @override
  String get confirmationTooLateToChange => 'Too late to change that';

  @override
  String get confirmationChangeAddress => 'Change address';

  @override
  String get ordersTitle => 'Your orders';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptyMessage =>
      'When you place an order it’ll appear here with its delivery status.';

  @override
  String get ordersEmptyAction => 'Browse the shop';

  @override
  String get ordersPickOne => 'Choose an order to see its details.';

  @override
  String orderItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get orderNotFoundTitle => 'Order not found';

  @override
  String orderNotFoundMessage(String id) {
    return 'We couldn’t find order $id.';
  }

  @override
  String get orderAllOrders => 'All orders';

  @override
  String get orderItems => 'Items';

  @override
  String get orderCharged => 'Charged';

  @override
  String get orderDelivery => 'Delivery';

  @override
  String get orderGift => 'Gift';

  @override
  String get orderGiftWrapped => 'Gift wrapped';

  @override
  String get orderPayment => 'Payment';

  @override
  String get orderCancelAction => 'Cancel this order';

  @override
  String orderReturnAction(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Return items · $days days left',
      one: 'Return items · 1 day left',
    );
    return '$_temp0';
  }

  @override
  String get orderViewReceipt => 'View receipt';

  @override
  String get orderBuyAgain => 'Buy these again';

  @override
  String get orderCancelConfirm => 'Cancel order';

  @override
  String get orderCancelKeep => 'Keep it';

  @override
  String get orderCancelled => 'Order cancelled';

  @override
  String get orderTooLateToCancel =>
      'Too late to cancel — it has already shipped';

  @override
  String get orderRefundedNothingComing =>
      'This order was refunded. Nothing is on its way.';

  @override
  String get orderCancelledNothingComing =>
      'This order was cancelled and won’t be delivered.';

  @override
  String get orderDeliveredReturnInProgress => 'Delivered · return in progress';

  @override
  String orderArrivingBy(String date) {
    return 'Arriving by $date';
  }

  @override
  String get orderReturnInProgress => 'Return in progress';

  @override
  String get orderRefundedToCardAndCredit =>
      'refunded to your card and store credit';

  @override
  String orderRefundedTo(String method) {
    return 'refunded to $method';
  }

  @override
  String orderRefundExpectedBy(String date) {
    return 'expect your refund by $date';
  }

  @override
  String get orderWithdrawReturn => 'Withdraw return';

  @override
  String get returnTitle => 'Return items';

  @override
  String get returnTitleShort => 'Return';

  @override
  String get returnNoLongerPossible => 'This order can no longer be returned';

  @override
  String returnStarted(String amount) {
    return 'Return started · $amount';
  }

  @override
  String get returnNothingTitle => 'Nothing to return';

  @override
  String get returnNothingMessage => 'We couldn’t find that order.';

  @override
  String get returnClearSelection => 'Clear selection';

  @override
  String get returnSelectEverything => 'Select everything';

  @override
  String get returnWhy => 'Why?';

  @override
  String get returnNoteLabel => 'Anything else? (optional)';

  @override
  String get returnChooseItems => 'Choose items to return';

  @override
  String returnRequestRefund(String amount) {
    return 'Request $amount refund';
  }

  @override
  String get returnEstimate => 'Refund estimate';

  @override
  String get returnBackOnCard => 'Back on your card';

  @override
  String get returnPostageOnUs =>
      'We got this wrong, so return postage is on us.';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptUnavailableTitle => 'Receipt unavailable';

  @override
  String get receiptCopy => 'Copy';

  @override
  String get receiptCopied => 'Receipt copied';

  @override
  String get receiptShare => 'Share';

  @override
  String receiptShareSubject(String id) {
    return 'Aster receipt $id';
  }

  @override
  String get receiptExportPdf => 'Export PDF';

  @override
  String get receiptHeading => 'ASTER — RECEIPT';

  @override
  String receiptOrderLine(String id) {
    return 'Order $id';
  }

  @override
  String get receiptStatus => 'Status';

  @override
  String get receiptItemsHeading => 'ITEMS';

  @override
  String get receiptTotalCaps => 'TOTAL';

  @override
  String get receiptChargedCaps => 'CHARGED';

  @override
  String get receiptDeliveryLabel => 'Delivery';

  @override
  String get receiptShipTo => 'Ship to';

  @override
  String get receiptPaidWith => 'Paid with';

  @override
  String get receiptCourier => 'Courier';

  @override
  String get receiptNote => 'Note';

  @override
  String get receiptGiftMessage => 'Message';

  @override
  String receiptReturnLine(String reason, String amount) {
    return 'RETURN: $reason — refund $amount';
  }

  @override
  String get receiptDemoFooter =>
      'Aster is a demo storefront. No payment was taken.';

  @override
  String get returnPickSomething =>
      'Pick at least one item to see what comes back.';

  @override
  String get returnLineItems => 'Items';

  @override
  String get returnLineOriginalShipping => 'Original shipping';

  @override
  String get returnLineTax => 'Tax';

  @override
  String get returnPostageDeducted =>
      'Return postage is deducted from your refund unless the item arrived damaged or incorrect.';

  @override
  String get receiptOrder => 'Order';

  @override
  String get receiptPlaced => 'Placed';

  @override
  String get receiptShipsTo => 'Ships to';

  @override
  String get receiptReturn => 'Return';

  @override
  String get receiptRefund => 'Refund';

  @override
  String get receiptQty => 'Qty';

  @override
  String get receiptItem => 'Item';

  @override
  String get receiptLineTotal => 'Total';

  @override
  String receiptPdfTitle(String id) {
    return 'Aster receipt $id';
  }

  @override
  String bagCheckoutWithTotal(String amount) {
    return 'Checkout · $amount';
  }

  @override
  String bagFreeShippingNudge(String amount) {
    return 'Add $amount for free shipping';
  }

  @override
  String changeWindowLeft(String time) {
    return 'Changed your mind? $time left';
  }

  @override
  String get changeWindowBody =>
      'Until then this order can be cancelled or sent somewhere else.';

  @override
  String get orderCancelMessage =>
      'It hasn’t shipped yet, so it can still be stopped. This can’t be undone.';

  @override
  String orderPlacedOn(String date) {
    return 'Placed $date';
  }

  @override
  String get returnWhatHeading => 'What are you sending back?';

  @override
  String returnDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left to return this order.',
      one: '1 day left to return this order.',
    );
    return '$_temp0';
  }

  @override
  String get addressLabelField => 'Label';

  @override
  String get addressFullName => 'Full name';

  @override
  String get addressStreet => 'Street address';

  @override
  String get addressCity => 'City';

  @override
  String get addressCountry => 'Country';

  @override
  String get addressSave => 'Save address';

  @override
  String get addressPostcodeUs => 'ZIP';

  @override
  String get addressPostcodeOther => 'Postcode';
}
