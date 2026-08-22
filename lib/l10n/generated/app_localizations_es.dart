// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppL10nEs extends AppL10n {
  AppL10nEs([String locale = 'es']) : super(locale);

  @override
  String get orderStatusProcessing => 'En preparación';

  @override
  String get orderStatusShipped => 'Enviado';

  @override
  String get orderStatusDelivered => 'Entregado';

  @override
  String get orderStatusCancelled => 'Cancelado';

  @override
  String get orderStatusReturnRequested => 'Devolución solicitada';

  @override
  String get orderStatusRefunded => 'Reembolsado';

  @override
  String get dropOffHandToMe => 'Entregármelo en mano';

  @override
  String get dropOffAtDoor => 'Dejarlo en mi puerta';

  @override
  String get dropOffWithNeighbour => 'Dejarlo con un vecino';

  @override
  String get dropOffSafePlace => 'Dejarlo en un lugar seguro';

  @override
  String get returnReasonWrongSize => 'Talla o ajuste incorrecto';

  @override
  String get returnReasonNotAsDescribed => 'No es como se describía';

  @override
  String get returnReasonDamaged => 'Llegó dañado';

  @override
  String get returnReasonWrongItem => 'Enviaron el artículo equivocado';

  @override
  String get returnReasonChangedMind => 'Cambié de opinión';

  @override
  String get returnReasonOther => 'Otro motivo';

  @override
  String get authErrorEmailInvalid =>
      'Introduce una dirección de correo válida';

  @override
  String get authErrorEmailTaken => 'Ya hay una cuenta con ese correo';

  @override
  String get authErrorNameRequired => 'Dinos cómo te llamas';

  @override
  String get authErrorPasswordTooShort => 'Usa al menos 8 caracteres';

  @override
  String get authErrorPasswordTooCommon =>
      'Esa contraseña es demasiado fácil de adivinar';

  @override
  String get authErrorPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get authErrorCredentialsWrong =>
      'El correo o la contraseña no son correctos';

  @override
  String get deliveryStandardLabel => 'Estándar';

  @override
  String get deliveryStandardBlurb => '3–5 días laborables';

  @override
  String get deliveryExpressLabel => 'Exprés';

  @override
  String get deliveryExpressBlurb => 'El siguiente día laborable';

  @override
  String get deliveryPickupLabel => 'Recoger en tienda';

  @override
  String get deliveryPickupBlurb => 'Listo en unas 2 horas';

  @override
  String priceReducedFrom(String price, String was, int percent) {
    return '$price, rebajado de $was, $percent% de descuento';
  }

  @override
  String ratingOutOfFive(String rating) {
    return 'Valorado con $rating sobre 5';
  }

  @override
  String ratingOutOfFiveWithReviews(String rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reseñas',
      one: '1 reseña',
    );
    return 'Valorado con $rating sobre 5 a partir de $_temp0';
  }

  @override
  String get stockSoldOut => 'Agotado';

  @override
  String stockOnlyLeft(int count) {
    return 'Solo quedan $count';
  }

  @override
  String get badgeNew => 'Nuevo';

  @override
  String get quantityLabel => 'Cantidad';

  @override
  String get decreaseQuantity => 'Reducir la cantidad';

  @override
  String get increaseQuantity => 'Aumentar la cantidad';

  @override
  String get removeItem => 'Quitar';

  @override
  String get saveToWishlist => 'Guardar en la lista de deseos';

  @override
  String get removeFromWishlist => 'Quitar de la lista de deseos';

  @override
  String get productImage => 'Imagen del producto';

  @override
  String productImageOfCount(int index, int total) {
    return 'Imagen $index de $total del producto';
  }

  @override
  String get enlargeHint => 'ampliar';

  @override
  String get itemNoLongerAvailable => 'Artículo ya no disponible';

  @override
  String itemsNoLongerSold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos ya no están a la venta',
      one: '1 artículo ya no está a la venta',
    );
    return '$_temp0';
  }

  @override
  String get catalogUnreachableMessage =>
      'Tus artículos están a salvo: lo que no podemos es conectar con la tienda para consultarlos.';

  @override
  String get couldNotLoadBag => 'No pudimos cargar tu bolsa';

  @override
  String get couldNotLoadSaves => 'No pudimos cargar lo que guardaste';

  @override
  String get retry => 'Reintentar';

  @override
  String get reorderAdded => 'Añadido de nuevo a tu bolsa';

  @override
  String reorderNoneAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ninguno de estos sigue disponible',
      one: 'Ese artículo ya no está disponible',
    );
    return '$_temp0';
  }

  @override
  String reorderPartial(int added, int skipped) {
    return '$added añadidos de nuevo: $skipped ya no están disponibles';
  }

  @override
  String get viewBag => 'Ver la bolsa';

  @override
  String get bagTitle => 'Tu bolsa';

  @override
  String get bagClear => 'Vaciar';

  @override
  String get bagEmptyTitle => 'Tu bolsa está vacía';

  @override
  String get bagEmptyMessage =>
      'En cuanto añadas algo que te guste, aparecerá aquí.';

  @override
  String get bagEmptyAction => 'Empezar a comprar';

  @override
  String get bagConfirmClearTitle => '¿Vaciar la bolsa?';

  @override
  String get bagConfirmClearMessage =>
      'Esto quita todos los artículos y no se puede deshacer.';

  @override
  String get bagConfirmKeep => 'Conservarlos';

  @override
  String get bagConfirmEmpty => 'Vaciar la bolsa';

  @override
  String bagRemovedItem(String name) {
    return '$name quitado';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get bagSaveForLater => 'Guardar para después';

  @override
  String get bagCheckout => 'Pagar';

  @override
  String get savedForLaterTitle => 'Guardado para después';

  @override
  String savedForLaterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos esperando',
      one: '1 artículo esperando',
    );
    return '$_temp0';
  }

  @override
  String get savedMoveToBag => 'Pasar a la bolsa';

  @override
  String get summaryTitle => 'Resumen del pedido';

  @override
  String get summarySubtotal => 'Subtotal';

  @override
  String get summaryDiscount => 'Descuento';

  @override
  String summaryDiscountWithCode(String code) {
    return 'Descuento ($code)';
  }

  @override
  String get summaryShipping => 'Envío';

  @override
  String get summaryFree => 'Gratis';

  @override
  String get summaryGiftWrap => 'Envoltorio de regalo';

  @override
  String get summaryTax => 'Impuestos estimados';

  @override
  String get summaryTotal => 'Total';

  @override
  String get summaryOrderTotal => 'Total del pedido';

  @override
  String get summaryStoreCredit => 'Saldo de la tienda';

  @override
  String get summaryToPay => 'A pagar';

  @override
  String get promoHint => 'Código promocional';

  @override
  String get promoApply => 'Aplicar';

  @override
  String get promoRemove => 'Quitar el código';

  @override
  String promoMinSpend(String amount) {
    return 'Gasta $amount para poder usarlo';
  }

  @override
  String promoBestCode(String code) {
    return 'Mejor código: $code';
  }

  @override
  String promoSaves(String amount) {
    return 'Ahorra $amount en esta bolsa';
  }

  @override
  String get checkoutTitle => 'Pago';

  @override
  String get checkoutStepShipping => 'Envío';

  @override
  String get checkoutStepPayment => 'Pago';

  @override
  String get checkoutStepReview => 'Revisión';

  @override
  String get checkoutBack => 'Atrás';

  @override
  String get checkoutContinue => 'Continuar';

  @override
  String checkoutSlideToPay(String amount) {
    return 'Desliza para pagar $amount';
  }

  @override
  String checkoutPay(String amount) {
    return 'Pagar $amount';
  }

  @override
  String get checkoutEmptyTitle => 'No hay nada que pagar';

  @override
  String get checkoutEmptyMessage => 'Tu bolsa está vacía.';

  @override
  String get checkoutEmptyAction => 'Ver la tienda';

  @override
  String get checkoutBiometricReason =>
      'Confirma tu identidad para realizar este pedido';

  @override
  String get checkoutBiometricCancelled =>
      'Pago cancelado: no se verificó tu identidad';

  @override
  String get checkoutBiometricUnavailable =>
      'Biometría no disponible: se continúa sin verificar';

  @override
  String get checkoutPaidByCredit => 'Saldo de la tienda';

  @override
  String get checkoutCardOnFile => 'Tarjeta guardada';

  @override
  String get checkoutShipTo => 'Enviar a';

  @override
  String get checkoutAddAddress => 'Añadir una dirección nueva';

  @override
  String get checkoutDelivery => 'Entrega';

  @override
  String get checkoutWhenItArrives => 'Cuando llegue';

  @override
  String get checkoutIfYoureOut => 'Si no estás en casa';

  @override
  String get checkoutCourierNote => 'Algo más para el repartidor (opcional)';

  @override
  String get checkoutCourierNoteHint =>
      'Código de la verja 1234: la puerta azul del lateral';

  @override
  String get checkoutKnockAndWait =>
      'Llamaremos y esperaremos. Si no abre nadie, el paquete vuelve con el repartidor.';

  @override
  String get checkoutUnattendedRisk =>
      'Un paquete dejado sin vigilancia queda bajo tu responsabilidad una vez entregado.';

  @override
  String get checkoutPayWith => 'Pagar con';

  @override
  String get checkoutCreditCoversOrder =>
      'Tu saldo cubre este pedido. No se cargará ninguna tarjeta.';

  @override
  String get checkoutNoCards => 'No hay tarjetas guardadas';

  @override
  String get checkoutNoCardsBody =>
      'Añade una para continuar. Solo se guardan los cuatro últimos dígitos.';

  @override
  String get checkoutAddCard => 'Añadir una tarjeta';

  @override
  String get checkoutAddAnotherCard => 'Añadir otra tarjeta';

  @override
  String checkoutCardExpired(String date) {
    return 'Caducó en $date';
  }

  @override
  String checkoutCardExpires(String date) {
    return 'Caduca en $date';
  }

  @override
  String get checkoutBiometricNotice =>
      'Te pediremos que te verifiques antes de realizar el pedido.';

  @override
  String get checkoutDemoNotice =>
      'Pago de demostración: no se cobra ninguna tarjeta ni se recogen ni guardan datos de pago.';

  @override
  String get checkoutReviewTitle => 'Revisa tu pedido';

  @override
  String get checkoutShippingTo => 'Se envía a';

  @override
  String get checkoutNoAddress => 'No has elegido dirección';

  @override
  String get checkoutPayingWith => 'Se paga con';

  @override
  String get checkoutNoCard => 'No has elegido tarjeta';

  @override
  String checkoutQuantityShort(int count) {
    return 'Cant. $count';
  }

  @override
  String checkoutItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos',
      one: '1 artículo',
    );
    return '$_temp0';
  }

  @override
  String get creditUseSwitch => 'Usar el saldo de la tienda';

  @override
  String creditCoversOrder(String amount) {
    return '$amount cubre este pedido: no hace falta tarjeta';
  }

  @override
  String creditPartOfOrder(String applied, String balance) {
    return '$applied de $balance se usan en este pedido';
  }

  @override
  String creditKeptForLater(String balance) {
    return '$balance disponibles, guardados para otra vez';
  }

  @override
  String get giftWrapTitle => 'Envoltorio de regalo';

  @override
  String giftWrapSubtitle(String price) {
    return 'Envuelto en papel de seda y lazo · $price';
  }

  @override
  String get giftMessageLabel => 'Mensaje de regalo (opcional)';

  @override
  String get giftMessageHint => '¡Feliz cumpleaños!';

  @override
  String get giftPricesHidden => 'En los regalos, el albarán va sin precios.';

  @override
  String promoAutoApplied(String code) {
    return 'Hemos aplicado $code';
  }

  @override
  String promoAutoAppliedBody(String description) {
    return 'El mejor código para este pedido: $description';
  }

  @override
  String get promoAutoAppliedRemove => 'Quitar';

  @override
  String get confirmationNotFoundTitle => 'No encontramos el pedido';

  @override
  String confirmationNotFoundMessage(String id) {
    return 'No pudimos encontrar el pedido $id.';
  }

  @override
  String get confirmationBackToShop => 'Volver a la tienda';

  @override
  String get confirmationTitle => 'Pedido confirmado';

  @override
  String confirmationThanks(String id) {
    return '¡Gracias! Estamos preparando el pedido $id para enviarlo.';
  }

  @override
  String get confirmationItems => 'Artículos';

  @override
  String get confirmationTotalPaid => 'Total pagado';

  @override
  String get confirmationArrivesBy => 'Llega antes del';

  @override
  String get confirmationPaidWith => 'Pagado con';

  @override
  String get confirmationTrack => 'Seguir este pedido';

  @override
  String get confirmationKeepShopping => 'Seguir comprando';

  @override
  String get confirmationCancelTitle => '¿Cancelar este pedido?';

  @override
  String get confirmationCancelMessage =>
      'No se ha cobrado nada y los artículos vuelven a tu bolsa.';

  @override
  String get confirmationCancelConfirm => 'Cancelar el pedido';

  @override
  String get confirmationCancelled => 'Pedido cancelado';

  @override
  String get confirmationTooLateToCancel =>
      'Ya es tarde para cancelar: puedes seguirlo';

  @override
  String confirmationAddressChanged(String label) {
    return 'Lo enviaremos a $label';
  }

  @override
  String get confirmationTooLateToChange => 'Ya es tarde para cambiarlo';

  @override
  String get confirmationChangeAddress => 'Cambiar la dirección';

  @override
  String get ordersTitle => 'Tus pedidos';

  @override
  String get ordersEmptyTitle => 'Aún no hay pedidos';

  @override
  String get ordersEmptyMessage =>
      'Cuando hagas un pedido aparecerá aquí con su estado de entrega.';

  @override
  String get ordersEmptyAction => 'Ver la tienda';

  @override
  String get ordersPickOne => 'Elige un pedido para ver sus detalles.';

  @override
  String orderItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos',
      one: '1 artículo',
    );
    return '$_temp0';
  }

  @override
  String get orderNotFoundTitle => 'No encontramos el pedido';

  @override
  String orderNotFoundMessage(String id) {
    return 'No pudimos encontrar el pedido $id.';
  }

  @override
  String get orderAllOrders => 'Todos los pedidos';

  @override
  String get orderItems => 'Artículos';

  @override
  String get orderCharged => 'Cobrado';

  @override
  String get orderDelivery => 'Entrega';

  @override
  String get orderGift => 'Regalo';

  @override
  String get orderGiftWrapped => 'Envuelto para regalo';

  @override
  String get orderPayment => 'Pago';

  @override
  String get orderCancelAction => 'Cancelar este pedido';

  @override
  String orderReturnAction(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Devolver artículos · quedan $days días',
      one: 'Devolver artículos · queda 1 día',
    );
    return '$_temp0';
  }

  @override
  String get orderViewReceipt => 'Ver el recibo';

  @override
  String get orderBuyAgain => 'Volver a comprarlos';

  @override
  String get orderCancelConfirm => 'Cancelar el pedido';

  @override
  String get orderCancelKeep => 'Conservarlo';

  @override
  String get orderCancelled => 'Pedido cancelado';

  @override
  String get orderTooLateToCancel =>
      'Ya es tarde para cancelar: ya se ha enviado';

  @override
  String get orderRefundedNothingComing =>
      'Este pedido se reembolsó. No hay nada en camino.';

  @override
  String get orderCancelledNothingComing =>
      'Este pedido se canceló y no se entregará.';

  @override
  String get orderDeliveredReturnInProgress =>
      'Entregado · devolución en curso';

  @override
  String orderArrivingBy(String date) {
    return 'Llega antes del $date';
  }

  @override
  String get orderReturnInProgress => 'Devolución en curso';

  @override
  String get orderRefundedToCardAndCredit =>
      'reembolsado a tu tarjeta y a tu saldo';

  @override
  String orderRefundedTo(String method) {
    return 'reembolsado a $method';
  }

  @override
  String orderRefundExpectedBy(String date) {
    return 'tu reembolso llegará antes del $date';
  }

  @override
  String get orderWithdrawReturn => 'Retirar la devolución';

  @override
  String get returnTitle => 'Devolver artículos';

  @override
  String get returnTitleShort => 'Devolución';

  @override
  String get returnNoLongerPossible => 'Este pedido ya no se puede devolver';

  @override
  String returnStarted(String amount) {
    return 'Devolución iniciada · $amount';
  }

  @override
  String get returnNothingTitle => 'No hay nada que devolver';

  @override
  String get returnNothingMessage => 'No pudimos encontrar ese pedido.';

  @override
  String get returnClearSelection => 'Quitar la selección';

  @override
  String get returnSelectEverything => 'Seleccionar todo';

  @override
  String get returnWhy => '¿Por qué?';

  @override
  String get returnNoteLabel => '¿Algo más? (opcional)';

  @override
  String get returnChooseItems => 'Elige qué devolver';

  @override
  String returnRequestRefund(String amount) {
    return 'Solicitar un reembolso de $amount';
  }

  @override
  String get returnEstimate => 'Reembolso estimado';

  @override
  String get returnBackOnCard => 'De vuelta en tu tarjeta';

  @override
  String get returnPostageOnUs =>
      'El error es nuestro, así que el envío de vuelta corre de nuestra cuenta.';

  @override
  String get receiptTitle => 'Recibo';

  @override
  String get receiptUnavailableTitle => 'Recibo no disponible';

  @override
  String get receiptCopy => 'Copiar';

  @override
  String get receiptCopied => 'Recibo copiado';

  @override
  String get receiptShare => 'Compartir';

  @override
  String receiptShareSubject(String id) {
    return 'Recibo de Aster $id';
  }

  @override
  String get receiptExportPdf => 'Exportar en PDF';

  @override
  String get receiptHeading => 'ASTER — RECIBO';

  @override
  String receiptOrderLine(String id) {
    return 'Pedido $id';
  }

  @override
  String get receiptStatus => 'Estado';

  @override
  String get receiptItemsHeading => 'ARTÍCULOS';

  @override
  String get receiptTotalCaps => 'TOTAL';

  @override
  String get receiptChargedCaps => 'COBRADO';

  @override
  String get receiptDeliveryLabel => 'Entrega';

  @override
  String get receiptShipTo => 'Enviar a';

  @override
  String get receiptPaidWith => 'Pagado con';

  @override
  String get receiptCourier => 'Repartidor';

  @override
  String get receiptNote => 'Nota';

  @override
  String get receiptGiftMessage => 'Mensaje';

  @override
  String receiptReturnLine(String reason, String amount) {
    return 'DEVOLUCIÓN: $reason — reembolso de $amount';
  }

  @override
  String get receiptDemoFooter =>
      'Aster es una tienda de demostración. No se ha cobrado ningún pago.';

  @override
  String get returnPickSomething =>
      'Elige al menos un artículo para ver qué se te devuelve.';

  @override
  String get returnLineItems => 'Artículos';

  @override
  String get returnLineOriginalShipping => 'Envío original';

  @override
  String get returnLineTax => 'Impuestos';

  @override
  String get returnPostageDeducted =>
      'El envío de vuelta se descuenta del reembolso salvo que el artículo llegara dañado o equivocado.';

  @override
  String get receiptOrder => 'Pedido';

  @override
  String get receiptPlaced => 'Fecha';

  @override
  String get receiptShipsTo => 'Se envía a';

  @override
  String get receiptReturn => 'Devolución';

  @override
  String get receiptRefund => 'Reembolso';

  @override
  String get receiptQty => 'Cant.';

  @override
  String get receiptItem => 'Artículo';

  @override
  String get receiptLineTotal => 'Total';

  @override
  String receiptPdfTitle(String id) {
    return 'Recibo de Aster $id';
  }

  @override
  String bagCheckoutWithTotal(String amount) {
    return 'Pagar · $amount';
  }

  @override
  String bagFreeShippingNudge(String amount) {
    return 'Añade $amount y el envío es gratis';
  }

  @override
  String changeWindowLeft(String time) {
    return '¿Has cambiado de opinión? Quedan $time';
  }

  @override
  String get changeWindowBody =>
      'Hasta entonces puedes cancelar el pedido o enviarlo a otra dirección.';

  @override
  String get orderCancelMessage =>
      'Aún no se ha enviado, así que todavía se puede parar. Esto no se puede deshacer.';

  @override
  String orderPlacedOn(String date) {
    return 'Realizado el $date';
  }

  @override
  String get returnWhatHeading => '¿Qué vas a devolver?';

  @override
  String returnDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Quedan $days días para devolver este pedido.',
      one: 'Queda 1 día para devolver este pedido.',
    );
    return '$_temp0';
  }

  @override
  String get addressLabelField => 'Etiqueta';

  @override
  String get addressFullName => 'Nombre completo';

  @override
  String get addressStreet => 'Dirección';

  @override
  String get addressCity => 'Ciudad';

  @override
  String get addressCountry => 'País';

  @override
  String get addressSave => 'Guardar la dirección';

  @override
  String get addressPostcodeUs => 'Código postal';

  @override
  String get addressPostcodeOther => 'Código postal';

  @override
  String get addressPickerTitle => '¿A dónde lo enviamos?';

  @override
  String get addressPickerCurrent => 'Actual';
}
