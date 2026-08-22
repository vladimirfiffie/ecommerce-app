import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../state/biometrics_provider.dart';

/// Payment verification settings, plus a way to test the prompt before
/// trusting it with a real order.
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key, this.embedded = false});

  /// Shown inside the settings detail pane, where a back button
  /// would have nothing to pop.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<BiometricStatus> status = ref.watch(
      biometricStatusProvider,
    );
    final bool required = ref.watch(requireBiometricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        automaticallyImplyLeading: !embedded,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          switch (status) {
            AsyncLoading<BiometricStatus>() => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            AsyncData<BiometricStatus>(value: final BiometricStatus s) => _Body(
              status: s,
              required: required,
            ),
            _ => const _Body(
              status: BiometricStatus.unsupported,
              required: false,
            ),
          },
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verification happens entirely on your device. Aster never '
                    'sees your fingerprint or face — only whether the device '
                    'said yes. This build takes no real payments.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.status, required this.required});

  final BiometricStatus status;
  final bool required;

  Future<void> _test(BuildContext context, WidgetRef ref) async {
    final AuthOutcome outcome = await ref
        .read(biometricsProvider)
        .authenticate(reason: 'Test Aster’s payment verification');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (outcome) {
            AuthOutcome.success => 'Verified',
            AuthOutcome.failed => 'Not verified',
            AuthOutcome.unavailable =>
              'Unavailable on this device — orders would go through unverified',
          }),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                status.usable
                    ? Icons.fingerprint_rounded
                    : Icons.no_encryption_gmailerrorred_outlined,
                size: 26,
                color: status.usable
                    ? AppTheme.success
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      status.usable ? 'Ready' : 'Unavailable',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      status.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Verify before paying'),
          subtitle: Text(
            status.usable
                ? 'Ask for ${status.label.toLowerCase()} when placing an order'
                : 'Set up a fingerprint, face or screen lock first',
          ),
          value: required && status.usable,
          onChanged: status.usable
              ? (bool v) => ref.read(requireBiometricsProvider.notifier).set(v)
              : null,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _test(context, ref),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('Test the prompt'),
        ),
      ],
    );
  }
}
