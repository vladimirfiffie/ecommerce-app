import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/alerts_provider.dart';
import 'state/app_providers.dart';
import 'state/settings_provider.dart';
import 'state/whats_new_provider.dart';
import 'features/whats_new/whats_new_sheet.dart';

/// Router lives in a provider so hot reload and tests get a single instance.
final Provider<GoRouter> routerProvider = Provider<GoRouter>(
  (Ref ref) => createRouter(),
);

class NovaApp extends ConsumerStatefulWidget {
  const NovaApp({super.key});

  @override
  ConsumerState<NovaApp> createState() => _NovaAppState();
}

class _NovaAppState extends ConsumerState<NovaApp> {
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

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final bool useDynamic = settings.useDynamicColor;
        return MaterialApp.router(
          title: 'Nova',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.light(
            useDynamic ? lightDynamic?.harmonized() : null,
            seedColor: settings.preset.seed,
          ),
          darkTheme: AppTheme.dark(
            useDynamic ? darkDynamic?.harmonized() : null,
            amoled: settings.amoled,
            seedColor: settings.preset.seed,
          ),
          routerConfig: router,
        );
      },
    );
  }
}
