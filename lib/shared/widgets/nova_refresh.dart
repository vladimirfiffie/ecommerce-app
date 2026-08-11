import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haptic_kit/haptic_kit.dart';

import '../../state/app_providers.dart';
import '../../state/haptics_provider.dart';

/// Refetches the catalog from its source and rebuilds everything derived
/// from it.
///
/// Clears the repository's cache first — invalidating the provider alone
/// would just re-read that cache and hand back the same products.
Future<void> refreshCatalog(WidgetRef ref) {
  ref.read(productRepositoryProvider).clearCache();
  ref.invalidate(catalogProvider);
  return ref.read(catalogProvider.future);
}

/// Pull-to-refresh with a tick on the pull and a confirmation at the end.
///
/// The haptics are why this isn't just a bare [RefreshIndicator]: a pull
/// that fires with no feedback leaves you unsure whether it took, and the
/// closing tick tells you the new data has landed without watching the
/// spinner.
class NovaRefresh extends ConsumerWidget {
  const NovaRefresh({required this.child, super.key, this.onRefresh});

  final Widget child;

  /// Defaults to refetching the catalog.
  final Future<void> Function(WidgetRef ref)? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () async {
      final HapticService haptics = ref.read(hapticsProvider);
      // Fires the moment the gesture commits, not when it completes.
      unawaited(haptics.impact(HapticImpactStyle.light));

      try {
        await (onRefresh ?? refreshCatalog)(ref);
        unawaited(haptics.notification(HapticNotificationStyle.success));
      } on Object {
        // The catalog's own error state explains what went wrong; here we
        // only mark that the pull finished badly.
        unawaited(haptics.notification(HapticNotificationStyle.error));
      }
    },
    child: child,
  );
}
