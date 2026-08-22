import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';

/// Material's own strings — the ones the widgets say for themselves.
///
/// `flutter_localizations` cannot supply these any more. Its
/// `GlobalMaterialLocalizations` implements the framework's
/// `MaterialLocalizations`, and `material_ui` declares its own; the two are
/// different types, so the delegate satisfies a contract these widgets are no
/// longer asking about. material_ui ships exactly one locale of its own —
/// [DefaultMaterialLocalizations], US English — and its `MaterialApp` installs
/// that and nothing else, which is why a Spanish session came up warning that
/// no delegate supported it.
///
/// So the app brings its own. [DefaultMaterialLocalizations] is a plain class
/// with a const constructor, so Spanish is a subclass that overrides the
/// strings a shopper can actually reach and inherits the rest — the date-range
/// pickers and paginated tables this storefront has no screens for.
class _SpanishMaterialLocalizations extends DefaultMaterialLocalizations {
  const _SpanishMaterialLocalizations();

  // Navigation and chrome.
  @override
  String get openAppDrawerTooltip => 'Abrir el menú de navegación';
  @override
  String get backButtonTooltip => 'Atrás';
  @override
  String get closeButtonTooltip => 'Cerrar';
  @override
  String get deleteButtonTooltip => 'Eliminar';
  @override
  String get moreButtonTooltip => 'Más';
  @override
  String get showMenuTooltip => 'Mostrar el menú';
  @override
  String get drawerLabel => 'Menú de navegación';
  @override
  String get popupMenuLabel => 'Menú emergente';
  @override
  String get menuBarMenuLabel => 'Menú de la barra';
  @override
  String get dialogLabel => 'Diálogo';
  @override
  String get alertDialogLabel => 'Aviso';
  @override
  String get bottomSheetLabel => 'Hoja inferior';
  @override
  String get scrimLabel => 'Fondo';

  // Text fields and the selection toolbar.
  @override
  String get clearButtonTooltip => 'Borrar el texto';
  @override
  String get searchFieldLabel => 'Buscar';
  @override
  String get cutButtonLabel => 'Cortar';
  @override
  String get copyButtonLabel => 'Copiar';
  @override
  String get pasteButtonLabel => 'Pegar';
  @override
  String get selectAllButtonLabel => 'Seleccionar todo';
  @override
  String get lookUpButtonLabel => 'Buscar';
  @override
  String get searchWebButtonLabel => 'Buscar en la web';
  @override
  String get shareButtonLabel => 'Compartir';
  @override
  String get scanTextButtonLabel => 'Escanear texto';

  // Dialog actions.
  @override
  String get cancelButtonLabel => 'Cancelar';
  @override
  String get closeButtonLabel => 'Cerrar';
  @override
  String get continueButtonLabel => 'Continuar';
  @override
  String get okButtonLabel => 'Aceptar';
  @override
  String get saveButtonLabel => 'Guardar';
  @override
  String get viewLicensesButtonLabel => 'Ver las licencias';
  @override
  String get licensesPageTitle => 'Licencias';

  // Reachable through the license page and any paginated list.
  @override
  String get rowsPerPageTitle => 'Filas por página:';
  @override
  String get nextPageTooltip => 'Página siguiente';
  @override
  String get previousPageTooltip => 'Página anterior';
  @override
  String get firstPageTooltip => 'Primera página';
  @override
  String get lastPageTooltip => 'Última página';

  // Date and time pickers.
  @override
  String get datePickerHelpText => 'Selecciona la fecha';
  @override
  String get dateRangePickerHelpText => 'Selecciona el intervalo';
  @override
  String get dateInputLabel => 'Introduce la fecha';
  @override
  String get dateHelpText => 'dd/mm/aaaa';
  @override
  String get dateSeparator => '/';
  @override
  String get unspecifiedDate => 'Fecha';
  @override
  String get unspecifiedDateRange => 'Intervalo de fechas';
  @override
  String get dateRangeStartLabel => 'Fecha de inicio';
  @override
  String get dateRangeEndLabel => 'Fecha de fin';
  @override
  String get invalidDateFormatLabel => 'Formato no válido.';
  @override
  String get invalidDateRangeLabel => 'Intervalo no válido.';
  @override
  String get dateOutOfRangeLabel => 'Fuera del intervalo.';
  @override
  String get selectYearSemanticsLabel => 'Selecciona el año';
  @override
  String get currentDateLabel => 'Hoy';
  @override
  String get selectedDateLabel => 'Seleccionada';
  @override
  String get calendarModeButtonLabel => 'Cambiar al calendario';
  @override
  String get inputDateModeButtonLabel => 'Cambiar a la introducción manual';
  @override
  String get timePickerHourLabel => 'Hora';
  @override
  String get timePickerMinuteLabel => 'Minuto';
  @override
  String get timePickerDialHelpText => 'Selecciona la hora';
  @override
  String get timePickerInputHelpText => 'Introduce la hora';
  @override
  String get invalidTimeLabel => 'Introduce una hora válida';
  @override
  String get dialModeButtonLabel => 'Cambiar al selector circular';
  @override
  String get inputTimeModeButtonLabel => 'Cambiar a la introducción manual';

  // Spain writes the clock without an am/pm marker, so the dial's period
  // control is not something a Spanish shopper should be shown.
  @override
  TimeOfDayFormat timeOfDayFormat({bool alwaysUse24HourFormat = false}) =>
      TimeOfDayFormat.HH_colon_mm;
}

/// Serves Material's own strings for the locales the app supports.
///
/// Falls back to English for anything else rather than refusing to load, so
/// adding a locale to the app can never leave the widgets with nothing to say.
class AsterMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const AsterMaterialLocalizationsDelegate();

  static const AsterMaterialLocalizationsDelegate delegate =
      AsterMaterialLocalizationsDelegate();

  /// Every locale, because English is the fallback and always answers.
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(switch (locale.languageCode) {
        'es' => const _SpanishMaterialLocalizations(),
        _ => const DefaultMaterialLocalizations(),
      });

  @override
  bool shouldReload(AsterMaterialLocalizationsDelegate old) => false;
}

/// Everything the app needs looked up, in one list.
///
/// Deliberately not `AppL10n.localizationsDelegates`, which gen_l10n writes
/// with `GlobalMaterialLocalizations.delegate` in it. That one implements the
/// framework's `MaterialLocalizations`, and these widgets come from
/// `material_ui`, which asks for its own — so it would sit in the list
/// answering a question nobody is asking while Spanish widgets fell back to
/// English. [AsterMaterialLocalizationsDelegate] answers the real one.
///
/// The other two SDK delegates stay: `WidgetsLocalizations` comes from
/// `package:flutter/widgets.dart`, which material_ui re-exports, so it is
/// literally the same class — and Cupertino's is still the framework's, which
/// is what the adaptive controls ask for.
const List<LocalizationsDelegate<dynamic>> asterLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      AppL10n.delegate,
      AsterMaterialLocalizationsDelegate.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
