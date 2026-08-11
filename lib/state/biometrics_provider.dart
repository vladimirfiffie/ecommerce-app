import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';

/// What the device can do, resolved once at startup.
@immutable
class BiometricStatus {
  const BiometricStatus({
    required this.supported,
    required this.enrolled,
    required this.types,
  });

  static const BiometricStatus unsupported = BiometricStatus(
    supported: false,
    enrolled: false,
    types: <BiometricType>[],
  );

  /// Hardware exists and the platform plugin answered.
  final bool supported;

  /// The user has actually set up a fingerprint / face.
  final bool enrolled;

  final List<BiometricType> types;

  bool get usable => supported && enrolled;

  /// `Fingerprint`, `Face`, or a combined label.
  String get label {
    if (!supported) return 'No biometric hardware';
    if (!enrolled) return 'Nothing enrolled on this device';
    final Set<String> names = <String>{
      for (final BiometricType t in types)
        switch (t) {
          BiometricType.face => 'Face',
          BiometricType.fingerprint => 'Fingerprint',
          BiometricType.iris => 'Iris',
          BiometricType.strong => 'Biometrics',
          BiometricType.weak => 'Biometrics',
        },
    };
    return names.isEmpty ? 'Biometrics' : names.join(' · ');
  }
}

/// Outcome of an authentication attempt, so callers can tell "user said no"
/// from "device can't do this".
enum AuthOutcome {
  /// Identity confirmed.
  success,

  /// Cancelled or failed — do not proceed.
  failed,

  /// Nothing to authenticate against; the caller decides whether to continue.
  unavailable,
}

final Provider<LocalAuthentication> localAuthProvider =
    Provider<LocalAuthentication>((Ref ref) => LocalAuthentication());

/// Resolves the device's biometric capability once, then caches it.
final FutureProvider<BiometricStatus> biometricStatusProvider =
    FutureProvider<BiometricStatus>((Ref ref) async {
      if (!BiometricService.platformSupported) {
        return BiometricStatus.unsupported;
      }
      final LocalAuthentication auth = ref.watch(localAuthProvider);
      try {
        final bool supported =
            await auth.isDeviceSupported() && await auth.canCheckBiometrics;
        if (!supported) return BiometricStatus.unsupported;
        final List<BiometricType> types = await auth.getAvailableBiometrics();
        return BiometricStatus(
          supported: true,
          enrolled: types.isNotEmpty,
          types: types,
        );
      } on LocalAuthException {
        return BiometricStatus.unsupported;
      } on MissingPluginException {
        return BiometricStatus.unsupported;
      } on PlatformException {
        return BiometricStatus.unsupported;
      }
    });

/// Whether checkout must be confirmed with a biometric.
class RequireBiometricsNotifier extends Notifier<bool> {
  static const String _key = 'biometrics.requireForPayment';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  bool build() => _prefs.getBool(_key) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await _prefs.setBool(_key, value);
  }
}

final NotifierProvider<RequireBiometricsNotifier, bool>
requireBiometricsProvider = NotifierProvider<RequireBiometricsNotifier, bool>(
  RequireBiometricsNotifier.new,
);

/// Wraps `local_auth` the same way [HapticService] wraps haptics: guarded by
/// platform, never throwing, and honouring the user's setting.
class BiometricService {
  const BiometricService(this._auth);

  final LocalAuthentication _auth;

  /// local_auth only implements Android and iOS.
  static bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Codes that mean "this device can't verify you", as opposed to "you
  /// declined". The caller is allowed to continue on these; a refusal must
  /// stop the order.
  static const Set<LocalAuthExceptionCode> _unavailableCodes =
      <LocalAuthExceptionCode>{
        LocalAuthExceptionCode.noCredentialsSet,
        LocalAuthExceptionCode.noBiometricsEnrolled,
        LocalAuthExceptionCode.noBiometricHardware,
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable,
        LocalAuthExceptionCode.uiUnavailable,
        LocalAuthExceptionCode.deviceError,
      };

  /// Prompts for a biometric.
  ///
  /// `biometricOnly` is left false so a device PIN or pattern also works —
  /// otherwise a shopper whose sensor is wet or locked out would be shut out
  /// of their own order with no way through.
  Future<AuthOutcome> authenticate({required String reason}) async {
    if (!platformSupported) return AuthOutcome.unavailable;
    try {
      final bool ok = await _auth.authenticate(
        localizedReason: reason,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
      return ok ? AuthOutcome.success : AuthOutcome.failed;
    } on LocalAuthException catch (error) {
      return _unavailableCodes.contains(error.code)
          ? AuthOutcome.unavailable
          : AuthOutcome.failed;
    } on MissingPluginException {
      return AuthOutcome.unavailable;
    } on PlatformException {
      return AuthOutcome.unavailable;
    }
  }

  Future<void> stop() async {
    if (!platformSupported) return;
    try {
      await _auth.stopAuthentication();
    } on LocalAuthException {
      /* nothing in flight */
    } on MissingPluginException {
      /* not this platform */
    } on PlatformException {
      /* not this platform */
    }
  }
}

final Provider<BiometricService> biometricsProvider =
    Provider<BiometricService>(
      (Ref ref) => BiometricService(ref.watch(localAuthProvider)),
    );
