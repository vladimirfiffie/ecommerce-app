import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/settings_provider.dart';

/// Router lives in a provider so hot reload and tests get a single instance.
final Provider<GoRouter> routerProvider = Provider<GoRouter>(
  (Ref ref) => createRouter(),
);

class NovaApp extends ConsumerWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final GoRouter router = ref.watch(routerProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final bool useDynamic = settings.useDynamicColor;
        return MaterialApp.router(
          title: 'Nova',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.light(useDynamic ? lightDynamic?.harmonized() : null),
          darkTheme: AppTheme.dark(
            useDynamic ? darkDynamic?.harmonized() : null,
            amoled: settings.amoled,
          ),
          routerConfig: router,
        );
      },
    );
  }
}
