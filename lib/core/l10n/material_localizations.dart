import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';

/// Everything the app needs looked up, in one list.
///
/// Deliberately not `AppL10n.localizationsDelegates`. gen_l10n writes that
/// list against `package:flutter_localizations`, whose delegates implement the
/// *framework's* `MaterialLocalizations` — and these widgets come from
/// `material_ui`, which declares its own. The framework's delegates load
/// happily and then answer to nobody, which shows up as a Spanish session
/// warning that no delegate supports it while every Material string stays
/// English.
///
/// `material_ui` ships its own `GlobalMaterialLocalizations`, covering the
/// same 116 locales, so the fix is to take its delegates rather than the
/// SDK's. Nothing is translated here.
const List<LocalizationsDelegate<dynamic>> asterLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      AppL10n.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ];
