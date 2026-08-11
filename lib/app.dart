import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/alerts_provider.dart';
import 'state/app_providers.dart';
import 'state/settings_provider.dart';

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
    });
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
