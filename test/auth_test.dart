import 'dart:convert';

import 'package:ecommerce_app/data/models/account.dart';
import 'package:ecommerce_app/state/auth_provider.dart';
import 'package:ecommerce_app/state/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PBKDF2', () {
    test('matches the RFC 6070 test vector', () {
      // RFC 6070 is specified for HMAC-SHA1; this is the widely-published
      // SHA-256 equivalent for P="password", S="salt", c=1, dkLen=32.
      const String expected =
          '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b';
      final String salt = base64Encode('salt'.codeUnits);
      final String actual = PasswordHasher.derive(
        password: 'password',
        salt: salt,
        iterations: 1,
      );
      final String hex = base64Decode(
        actual,
      ).map((int b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, expected);
    });

    test('is deterministic for the same salt', () {
      final String salt = PasswordHasher.newSalt();
      expect(
        PasswordHasher.derive(password: 'hunter22', salt: salt, iterations: 50),
        PasswordHasher.derive(password: 'hunter22', salt: salt, iterations: 50),
      );
    });

    test('a different salt gives a different hash for the same password', () {
      final String a = PasswordHasher.derive(
        password: 'hunter22',
        salt: PasswordHasher.newSalt(),
        iterations: 50,
      );
      final String b = PasswordHasher.derive(
        password: 'hunter22',
        salt: PasswordHasher.newSalt(),
        iterations: 50,
      );
      expect(a, isNot(b));
    });

    test('salts are random and non-trivial', () {
      final Set<String> salts = <String>{
        for (int i = 0; i < 50; i++) PasswordHasher.newSalt(),
      };
      expect(salts, hasLength(50));
      expect(base64Decode(salts.first), hasLength(16));
    });

    test('constant-time compare still compares correctly', () {
      expect(PasswordHasher.matches('abc', 'abc'), isTrue);
      expect(PasswordHasher.matches('abc', 'abd'), isFalse);
      expect(PasswordHasher.matches('abc', 'abcd'), isFalse);
      expect(PasswordHasher.matches('', ''), isTrue);
    });
  });

  group('validation', () {
    test('rejects short and common passwords', () {
      expect(
        AuthNotifier.validatePassword('short'),
        AuthError.passwordTooShort,
      );
      expect(
        AuthNotifier.validatePassword('password'),
        AuthError.passwordTooCommon,
      );
      expect(
        AuthNotifier.validatePassword('PASSWORD123'),
        AuthError.passwordTooCommon,
        reason: 'the common list is case-insensitive',
      );
      expect(AuthNotifier.validatePassword('correct horse'), isNull);
    });

    test('catches mismatched confirmation', () {
      expect(
        AuthNotifier.validatePassword('goodpassword', confirm: 'goodpassward'),
        AuthError.passwordMismatch,
      );
      expect(
        AuthNotifier.validatePassword('goodpassword', confirm: 'goodpassword'),
        isNull,
      );
    });

    test('email shape', () {
      expect(AuthNotifier.isValidEmail('a@b.co'), isTrue);
      expect(AuthNotifier.isValidEmail('  A@B.CO '), isTrue);
      expect(AuthNotifier.isValidEmail('nope'), isFalse);
      expect(AuthNotifier.isValidEmail('no@domain'), isFalse);
      expect(AuthNotifier.isValidEmail(''), isFalse);
    });
  });

  group('sign up', () {
    test('creates an account and signs in', () async {
      final ProviderContainer c = await testContainer();
      await c
          .read(authProvider.notifier)
          .signUp(
            name: 'Bbo',
            email: 'Bbo@Example.com',
            password: 'correct horse',
            confirmPassword: 'correct horse',
          );

      final AuthState state = c.read(authProvider);
      expect(state.signedIn, isTrue);
      expect(state.account!.name, 'Bbo');
      expect(state.account!.email, 'bbo@example.com', reason: 'normalised');
      expect(state.busy, isFalse);
    });

    test('never writes the password to storage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = await testContainer();

      const String secret = 'super secret pw';
      await c
          .read(authProvider.notifier)
          .signUp(name: 'Bbo', email: 'b@e.co', password: secret);

      final String dump = prefs
          .getKeys()
          .map((String k) => '${prefs.get(k)}')
          .join('|');
      expect(dump, isNot(contains(secret)));
      expect(c.read(authProvider).account!.hash, isNot(contains(secret)));
    });

    test('rejects a duplicate email regardless of case', () async {
      final ProviderContainer c = await testContainer();
      final AuthNotifier auth = c.read(authProvider.notifier);
      await auth.signUp(name: 'A', email: 'dup@e.co', password: 'passphrase1');

      await expectLater(
        auth.signUp(name: 'B', email: 'DUP@e.co', password: 'passphrase2'),
        throwsA(
          isA<AuthException>().having(
            (AuthException e) => e.error,
            'error',
            AuthError.emailTaken,
          ),
        ),
      );
    });

    test('rejects a blank name and a bad email', () async {
      final ProviderContainer c = await testContainer();
      final AuthNotifier auth = c.read(authProvider.notifier);

      await expectLater(
        auth.signUp(name: '  ', email: 'a@b.co', password: 'passphrase1'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        auth.signUp(name: 'A', email: 'bad', password: 'passphrase1'),
        throwsA(isA<AuthException>()),
      );
      expect(c.read(authProvider).signedIn, isFalse);
    });

    test('a rejected sign-up leaves busy cleared', () async {
      final ProviderContainer c = await testContainer();
      final AuthNotifier auth = c.read(authProvider.notifier);
      await auth.signUp(name: 'A', email: 'a@b.co', password: 'passphrase1');
      await auth.signOut();

      await expectLater(
        auth.signUp(name: 'B', email: 'a@b.co', password: 'passphrase2'),
        throwsA(isA<AuthException>()),
      );
      expect(c.read(authProvider).busy, isFalse);
    });
  });

  group('sign in', () {
    Future<ProviderContainer> withAccount() async {
      final ProviderContainer c = await testContainer();
      await c
          .read(authProvider.notifier)
          .signUp(name: 'Bbo', email: 'bbo@e.co', password: 'correct horse');
      await c.read(authProvider.notifier).signOut();
      return c;
    }

    test('accepts the right password', () async {
      final ProviderContainer c = await withAccount();
      await c
          .read(authProvider.notifier)
          .signIn(email: 'bbo@e.co', password: 'correct horse');
      expect(c.read(authProvider).signedIn, isTrue);
    });

    test('email is case-insensitive', () async {
      final ProviderContainer c = await withAccount();
      await c
          .read(authProvider.notifier)
          .signIn(email: '  BBO@E.CO ', password: 'correct horse');
      expect(c.read(authProvider).signedIn, isTrue);
    });

    test('rejects a wrong password', () async {
      final ProviderContainer c = await withAccount();
      await expectLater(
        c
            .read(authProvider.notifier)
            .signIn(email: 'bbo@e.co', password: 'wrong horse'),
        throwsA(
          isA<AuthException>().having(
            (AuthException e) => e.error,
            'error',
            AuthError.credentialsWrong,
          ),
        ),
      );
      expect(c.read(authProvider).signedIn, isFalse);
    });

    test('an unknown email gives the same error as a wrong password', () async {
      final ProviderContainer c = await withAccount();
      await expectLater(
        c
            .read(authProvider.notifier)
            .signIn(email: 'nobody@e.co', password: 'correct horse'),
        throwsA(
          isA<AuthException>().having(
            (AuthException e) => e.error,
            'error',
            AuthError.credentialsWrong,
          ),
        ),
        reason: 'must not reveal which emails are registered',
      );
    });
  });

  group('session', () {
    test('survives a restart', () async {
      final ProviderContainer first = await testContainer();
      await first
          .read(authProvider.notifier)
          .signUp(name: 'Bbo', email: 'bbo@e.co', password: 'correct horse');
      final String id = first.read(authProvider).account!.id;

      // Same backing store, fresh container.
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: <Override>[sharedPreferencesProviderOverride(prefs)],
      );
      addTearDown(second.dispose);

      expect(second.read(authProvider).account?.id, id);
    });

    test('signing out keeps the account so you can sign back in', () async {
      final ProviderContainer c = await testContainer();
      final AuthNotifier auth = c.read(authProvider.notifier);
      await auth.signUp(
        name: 'Bbo',
        email: 'bbo@e.co',
        password: 'correct horse',
      );
      await auth.signOut();
      expect(c.read(authProvider).signedIn, isFalse);

      await auth.signIn(email: 'bbo@e.co', password: 'correct horse');
      expect(c.read(authProvider).account!.name, 'Bbo');
    });

    test('deleting the account prevents signing back in', () async {
      final ProviderContainer c = await testContainer();
      final AuthNotifier auth = c.read(authProvider.notifier);
      await auth.signUp(
        name: 'Bbo',
        email: 'bbo@e.co',
        password: 'correct horse',
      );
      await auth.deleteAccount();
      expect(c.read(authProvider).signedIn, isFalse);

      await expectLater(
        auth.signIn(email: 'bbo@e.co', password: 'correct horse'),
        throwsA(isA<AuthException>()),
      );
    });

    test('corrupt account storage degrades to signed-out', () async {
      final ProviderContainer c = await testContainer(
        initialPrefs: const <String, Object>{
          'auth.accounts': 'not json',
          'auth.sessionId': 'acct-whatever',
        },
      );
      expect(c.read(authProvider).signedIn, isFalse);
    });
  });

  group('greeting integration', () {
    test('the signed-in name wins over the OS name', () async {
      final ProviderContainer c = await testContainer();
      await c
          .read(authProvider.notifier)
          .signUp(name: 'bbo', email: 'bbo@e.co', password: 'correct horse');

      expect(c.read(displayNameProvider), 'bbo');
      expect(
        greetingLine(DateTime(2026, 8, 10, 9), c.read(firstNameProvider)),
        'Good morning, bbo',
      );
    });

    test('renaming while signed in updates the account', () async {
      final ProviderContainer c = await testContainer();
      final AuthNotifier auth = c.read(authProvider.notifier);
      await auth.signUp(
        name: 'bbo',
        email: 'bbo@e.co',
        password: 'correct horse',
      );

      await c.read(displayNameProvider.notifier).set('Bbo Jones');
      expect(c.read(authProvider).account!.name, 'Bbo Jones');
      expect(c.read(firstNameProvider), 'Bbo');

      await auth.signOut();
      await auth.signIn(email: 'bbo@e.co', password: 'correct horse');
      expect(c.read(authProvider).account!.name, 'Bbo Jones');
    });
  });
}
