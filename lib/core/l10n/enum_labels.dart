import '../../data/models/delivery_option.dart';
import '../../data/models/drop_off.dart';
import '../../data/models/order.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/auth_provider.dart';

/// Spoken and written names for the enums the shopper actually sees.
///
/// These used to be `String` fields on the enums themselves, which read
/// nicely but put user-facing copy somewhere a `BuildContext` can never
/// reach — so it could never be translated. The enums now carry only what is
/// true regardless of language (ids, prices, timings, who pays postage), and
/// the words live here, behind the same lookup as the rest of the copy.
extension OrderStatusL10n on OrderStatus {
  String labelIn(AppL10n l10n) => switch (this) {
    OrderStatus.processing => l10n.orderStatusProcessing,
    OrderStatus.shipped => l10n.orderStatusShipped,
    OrderStatus.delivered => l10n.orderStatusDelivered,
    OrderStatus.cancelled => l10n.orderStatusCancelled,
    OrderStatus.returnRequested => l10n.orderStatusReturnRequested,
    OrderStatus.refunded => l10n.orderStatusRefunded,
  };
}

extension ReturnReasonL10n on ReturnReason {
  String labelIn(AppL10n l10n) => switch (this) {
    ReturnReason.wrongSize => l10n.returnReasonWrongSize,
    ReturnReason.notAsDescribed => l10n.returnReasonNotAsDescribed,
    ReturnReason.damaged => l10n.returnReasonDamaged,
    ReturnReason.wrongItem => l10n.returnReasonWrongItem,
    ReturnReason.changedMind => l10n.returnReasonChangedMind,
    ReturnReason.other => l10n.returnReasonOther,
  };
}

extension DeliveryOptionL10n on DeliveryOption {
  String labelIn(AppL10n l10n) => switch (this) {
    DeliveryOption.standard => l10n.deliveryStandardLabel,
    DeliveryOption.express => l10n.deliveryExpressLabel,
    DeliveryOption.pickup => l10n.deliveryPickupLabel,
  };

  String blurbIn(AppL10n l10n) => switch (this) {
    DeliveryOption.standard => l10n.deliveryStandardBlurb,
    DeliveryOption.express => l10n.deliveryExpressBlurb,
    DeliveryOption.pickup => l10n.deliveryPickupBlurb,
  };
}

extension DropOffL10n on DropOff {
  String labelIn(AppL10n l10n) => switch (this) {
    DropOff.handToMe => l10n.dropOffHandToMe,
    DropOff.atDoor => l10n.dropOffAtDoor,
    DropOff.withNeighbour => l10n.dropOffWithNeighbour,
    DropOff.safePlace => l10n.dropOffSafePlace,
  };
}

extension AuthErrorL10n on AuthError {
  String messageIn(AppL10n l10n) => switch (this) {
    AuthError.emailInvalid => l10n.authErrorEmailInvalid,
    AuthError.emailTaken => l10n.authErrorEmailTaken,
    AuthError.nameRequired => l10n.authErrorNameRequired,
    AuthError.passwordTooShort => l10n.authErrorPasswordTooShort,
    AuthError.passwordTooCommon => l10n.authErrorPasswordTooCommon,
    AuthError.passwordMismatch => l10n.authErrorPasswordMismatch,
    // Deliberately vague — see the ARB note. Naming which half was wrong
    // would tell an attacker whether an email is registered.
    AuthError.credentialsWrong => l10n.authErrorCredentialsWrong,
  };
}
