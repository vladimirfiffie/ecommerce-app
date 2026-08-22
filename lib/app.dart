import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart' show CupertinoThemeData;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/formatters.dart';
import 'l10n/generated/app_localizations.dart';
import 'state/alerts_provider.dart';
import 'state/app_providers.dart';
import 'state/auth_provider.dart';
import 'state/settings_provider.dart';
import 'state/whats_new_provider.dart';
import 'features/whats_new/whats_new_sheet.dart';

/// Router lives in a provider so hot reload and tests get a single instance.
final Provider<GoRouter> routerProvider = Provider<GoRouter>(
  (Ref ref) => createRouter(ref),
);

class AsterApp extends ConsumerStatefulWidget {
  const AsterApp({super.key});

  @override
  ConsumerState<AsterApp> createState() => _AsterAppState();
}

class _AsterAppState extends ConsumerState<AsterApp> {
  @override
  void initState() {
    super.initState();
    // Once the catalog is loaded, check anything the shopper asked to be told
    // about. Wrapped broadly because a failed alert sweep must never be able
    // to stop the app from starting.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(catalogProvider.future);
        if (mounted) await ref.read(alertSweeperProvider).sweep();
      } on Object catch (error) {
        debugPrint('alert sweep skipped: $error');
      }
      if (mounted) await _maybeShowWhatsNew();
    });
  }

  /// Shows release notes once per upgrade.
  ///
  /// A first install records the version silently instead — nobody needs a
  /// changelog for a version they never ran.
  Future<void> _maybeShowWhatsNew() async {
    // Not over the welcome screen. Left unmarked so it still gets shown once
    // the shopper is actually in the shop.
    if (!ref.read(pastAuthGateProvider)) return;

    final WhatsNewNotifier notifier = ref.read(whatsNewProvider.notifier);
    if (!notifier.shouldShow) {
      if (ref.read(whatsNewProvider).lastSeenVersion == null) {
        await notifier.markSeen();
      }
      return;
    }
    final BuildContext? ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await showWhatsNewSheet(ctx, notes: notifier.pending);
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsProvider);
    final GoRouter router = ref.watch(routerProvider);

    // Android only started reporting this alongside iOS recently. Nothing
    // wraps the app in a MediaQuery on device, so the platform's own view is
    // the fallback; a test can state it by wrapping this widget in one.
    final bool highContrast =
        MediaQuery.maybeHighContrastOf(context) ??
        MediaQueryData.fromView(View.of(context)).highContrast;

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final bool useDynamic = settings.useDynamicColor;
        final ThemeData light = AppTheme.light(
          useDynamic ? lightDynamic?.harmonized() : null,
          seedColor: settings.preset.seed,
          highContrast: highContrast,
        );
        final ThemeData dark = AppTheme.dark(
          useDynamic ? darkDynamic?.harmonized() : null,
          amoled: settings.amoled,
          seedColor: settings.preset.seed,
          highContrast: highContrast,
        );

        // AdaptiveApp, not MaterialApp: on Android this builds the same
        // MaterialApp it always did, and on iOS a CupertinoApp instead, so
        // the app takes the platform's own chrome rather than wearing
        // Material everywhere.
        return AdaptiveApp.router(
          title: 'Aster',
          material: (BuildContext _, PlatformTarget _) =>
              const MaterialAppData(debugShowCheckedModeBanner: false),
          cupertino: (BuildContext _, PlatformTarget _) =>
              const CupertinoAppData(debugShowCheckedModeBanner: false),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          // `formatPrice` and friends are plain functions with no context to
          // read a locale from, so the resolved locale is published to `intl`
          // here — the one place that knows what it ended up being.
          localeResolutionCallback:
              (Locale? device, Iterable<Locale> supported) {
                final Locale resolved = basicLocaleListResolution(
                  device == null ? const <Locale>[] : <Locale>[device],
                  supported,
                );
                final String tag = resolved.toLanguageTag().replaceAll(
                  '-',
                  '_',
                );
                if (Intl.defaultLocale != tag) {
                  Intl.defaultLocale = tag;
                  resetFormatters();
                }
                return resolved;
              },
          themeMode: settings.themeMode,
          materialLightTheme: light,
          materialDarkTheme: dark,
          // The Cupertino side takes the same palette rather than Apple's
          // defaults, so an iOS build is still recognisably this shop —
          // including whichever preset or wallpaper palette is in force.
          cupertinoLightTheme: CupertinoThemeData(
            brightness: Brightness.light,
            primaryColor: light.colorScheme.primary,
            scaffoldBackgroundColor: light.scaffoldBackgroundColor,
            barBackgroundColor: light.colorScheme.surface,
          ),
          cupertinoDarkTheme: CupertinoThemeData(
            brightness: Brightness.dark,
            primaryColor: dark.colorScheme.primary,
            scaffoldBackgroundColor: dark.scaffoldBackgroundColor,
            barBackgroundColor: dark.colorScheme.surface,
          ),
          routerConfig: router,
        );
      },
    );
  }
}
