import 'package:ecommerce_app/app.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/biometrics_provider.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart'
    show AuthMessages;
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Scriptable stand-in for the platform plugin.
class _FakeAuth implements LocalAuthentication {
  _FakeAuth({
    this.result = true,
    this.throws,
    this.deviceSupported = true,
    this.biometrics = const <BiometricType>[BiometricType.fingerprint],
  });

  bool result;
  LocalAuthException? throws;
  bool deviceSupported;
  List<BiometricType> biometrics;

  int attempts = 0;
  String? lastReason;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    attempts++;
    lastReason = localizedReason;
    if (throws case final LocalAuthException error) throw error;
    return result;
  }

  @override
  Future<bool> get canCheckBiometrics async => deviceSupported;

  @override
  Future<bool> isDeviceSupported() async => deviceSupported;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => biometrics;

  @override
  Future<bool> stopAuthentication() async => true;
}

void main() {
  setUpAll(configureTestEnvironment);
  setUp(stubHaptics);

  final Catalog catalog = Catalog(
    categories: <Category>[
      Category(
        id: 'fashion',
        label: 'Fashion',
        iconName: 'checkroom',
        imageUrl: '',
      ),
    ],
    products: <Product>[testProduct(id: 'tee', name: 'Linen Tee', price: 25)],
  );

  group('BiometricService', () {
    test('success when the device confirms', () async {
      final _FakeAuth auth = _FakeAuth();
      final BiometricService service = BiometricService(auth);
      expect(await service.authenticate(reason: 'why'), AuthOutcome.success);
      expect(auth.lastReason, 'why');
    });

    test('a plain false is a refusal, not an outage', () async {
      final BiometricService service = BiometricService(
        _FakeAuth(result: false),
      );
      expect(await service.authenticate(reason: 'r'), AuthOutcome.failed);
    });

    test('user cancellation is a refusal', () async {
      final BiometricService service = BiometricService(
        _FakeAuth(
          throws: const LocalAuthException(
            code: LocalAuthExceptionCode.userCanceled,
          ),
        ),
      );
      expect(await service.authenticate(reason: 'r'), AuthOutcome.failed);
    });

    test('lockout is a refusal — it must not wave the order through', () async {
      for (final LocalAuthExceptionCode code in <LocalAuthExceptionCode>[
        LocalAuthExceptionCode.biometricLockout,
        LocalAuthExceptionCode.temporaryLockout,
        LocalAuthExceptionCode.timeout,
        LocalAuthExceptionCode.systemCanceled,
        LocalAuthExceptionCode.userRequestedFallback,
      ]) {
        final BiometricService service = BiometricService(
          _FakeAuth(throws: LocalAuthException(code: code)),
        );
        expect(
          await service.authenticate(reason: 'r'),
          AuthOutcome.failed,
          reason: code.name,
        );
      }
    });

    test('missing hardware or enrolment is unavailable, not refusal', () async {
      for (final LocalAuthExceptionCode code in <LocalAuthExceptionCode>[
        LocalAuthExceptionCode.noCredentialsSet,
        LocalAuthExceptionCode.noBiometricsEnrolled,
        LocalAuthExceptionCode.noBiometricHardware,
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable,
      ]) {
        final BiometricService service = BiometricService(
          _FakeAuth(throws: LocalAuthException(code: code)),
        );
        expect(
          await service.authenticate(reason: 'r'),
          AuthOutcome.unavailable,
          reason: code.name,
        );
      }
    });

    test('unsupported platforms never prompt', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final _FakeAuth auth = _FakeAuth();
      final BiometricService service = BiometricService(auth);
      expect(await service.authenticate(reason: 'r'), AuthOutcome.unavailable);
      expect(auth.attempts, 0);
    });
  });

  group('status', () {
    test('reports enrolled biometrics', () async {
      setMockPrefs();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localAuthProvider.overrideWithValue(
            _FakeAuth(biometrics: const <BiometricType>[BiometricType.face]),
          ),
        ],
      );
      addTearDown(c.dispose);

      final BiometricStatus s = await c.read(biometricStatusProvider.future);
      expect(s.usable, isTrue);
      expect(s.label, 'Face');
    });

    test('hardware without enrolment is not usable', () async {
      setMockPrefs();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localAuthProvider.overrideWithValue(
            _FakeAuth(biometrics: const <BiometricType>[]),
          ),
        ],
      );
      addTearDown(c.dispose);

      final BiometricStatus s = await c.read(biometricStatusProvider.future);
      expect(s.supported, isTrue);
      expect(s.enrolled, isFalse);
      expect(s.usable, isFalse);
    });

    test('a device without biometric support reports unsupported', () async {
      setMockPrefs();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localAuthProvider.overrideWithValue(
            _FakeAuth(deviceSupported: false),
          ),
        ],
      );
      addTearDown(c.dispose);

      final BiometricStatus s = await c.read(biometricStatusProvider.future);
      expect(s.supported, isFalse);
      expect(s.usable, isFalse);
      expect(s.label, 'No biometric hardware');
    });

    test('setting round-trips', () async {
      final ProviderContainer c = await testContainer();
      expect(c.read(requireBiometricsProvider), isFalse);
      await c.read(requireBiometricsProvider.notifier).set(true);
      expect(c.read(requireBiometricsProvider), isTrue);
    });
  });

  group('checkout gate', () {
    Future<ProviderContainer> pumpCheckout(
      WidgetTester tester, {
      required _FakeAuth auth,
      required bool requireAuth,
    }) async {
      useMobileSurface(tester);
      setMockPrefs(<String, Object>{
        'biometrics.requireForPayment': requireAuth,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository(catalog),
          ),
          localAuthProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(c.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AsterApp()),
      );
      await settle(tester);

      await c.read(cartProvider.notifier).add(catalog.byId('tee')!);
      await settle(tester);
      await tester.tap(find.text('Bag'));
      await settle(tester);
      await tester.tap(find.text('Checkout'));
      await settle(tester);
      await tester.tap(find.text('Continue'));
      await settle(tester);
      await tester.tap(find.text('Continue'));
      await settle(tester);
      await tester.drag(find.byIcon(Icons.arrow_forward), const Offset(500, 0));
      await tester.pump(const Duration(milliseconds: 1400));
      await settle(tester);
      return c;
    }

    testWidgets('a refusal blocks the order', (WidgetTester tester) async {
      final _FakeAuth auth = _FakeAuth(result: false);
      final ProviderContainer c = await pumpCheckout(
        tester,
        auth: auth,
        requireAuth: true,
      );

      expect(auth.attempts, 1);
      expect(c.read(ordersProvider), isEmpty);
      expect(c.read(cartProvider), isNotEmpty, reason: 'bag must survive');
      expect(find.text('Order confirmed'), findsNothing);
    });

    testWidgets('a pass places the order', (WidgetTester tester) async {
      final _FakeAuth auth = _FakeAuth();
      final ProviderContainer c = await pumpCheckout(
        tester,
        auth: auth,
        requireAuth: true,
      );

      expect(auth.attempts, 1);
      expect(c.read(ordersProvider), hasLength(1));
      expect(c.read(cartProvider), isEmpty);
    });

    testWidgets('no prompt when the setting is off', (
      WidgetTester tester,
    ) async {
      final _FakeAuth auth = _FakeAuth(result: false);
      final ProviderContainer c = await pumpCheckout(
        tester,
        auth: auth,
        requireAuth: false,
      );

      expect(auth.attempts, 0);
      expect(c.read(ordersProvider), hasLength(1));
    });

    testWidgets('an unavailable sensor still lets the order through', (
      WidgetTester tester,
    ) async {
      final _FakeAuth auth = _FakeAuth(
        throws: const LocalAuthException(
          code: LocalAuthExceptionCode.noBiometricHardware,
        ),
      );
      final ProviderContainer c = await pumpCheckout(
        tester,
        auth: auth,
        requireAuth: true,
      );

      expect(auth.attempts, 1);
      expect(c.read(ordersProvider), hasLength(1));
    });
  });
}
