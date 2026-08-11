import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/account.dart';
import 'app_providers.dart';

/// Why a sign-in or sign-up attempt was rejected.
enum AuthError {
  emailInvalid('Enter a valid email address'),
  emailTaken('An account already uses that email'),
  nameRequired('Tell us your name'),
  passwordTooShort('Use at least 8 characters'),
  passwordTooCommon('That password is too easy to guess'),
  passwordMismatch('Those passwords don’t match'),
  // Deliberately vague: saying which half was wrong tells an attacker
  // whether an email is registered.
  credentialsWrong('Email or password is incorrect');

  const AuthError(this.message);

  final String message;
}

class AuthException implements Exception {
  const AuthException(this.error);

  final AuthError error;

  String get message => error.message;

  @override
  String toString() => 'AuthException(${error.name})';
}

/// Signed-in state.
@immutable
class AuthState {
  const AuthState({this.account, this.busy = false});

  /// Null while browsing as a guest.
  final Account? account;

  /// A hash is being derived — sign-in takes a beat by design.
  final bool busy;

  bool get signedIn => account != null;
}

/// Rejects the handful of passwords that show up in every breach list. Not a
/// substitute for a real policy, but it stops the worst choices.
const Set<String> _commonPasswords = <String>{
  'password',
  'password1',
  'password123',
  '12345678',
  '123456789',
  'qwertyui',
  'qwerty123',
  'iloveyou',
  'welcome1',
  'abc12345',
  'letmein1',
  'admin123',
};

final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

/// Local accounts and the current session.
///
/// Everything lives in `shared_preferences`; there is no server. Passwords are
/// never stored, only a PBKDF2 hash with a per-account salt.
class AuthNotifier extends Notifier<AuthState> {
  static const String _accountsKey = 'auth.accounts';
  static const String _sessionKey = 'auth.sessionId';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AuthState build() {
    final String? sessionId = _prefs.getString(_sessionKey);
    if (sessionId == null) return const AuthState();
    for (final Account a in _accounts()) {
      if (a.id == sessionId) return AuthState(account: a);
    }
    return const AuthState();
  }

  List<Account> _accounts() {
    final String? raw = _prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) return const <Account>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return <Account>[
        for (final Object? a in decoded)
          Account.fromJson(a! as Map<String, dynamic>),
      ];
    } on FormatException {
      return const <Account>[];
    }
  }

  Future<void> _writeAccounts(List<Account> accounts) => _prefs.setString(
    _accountsKey,
    jsonEncode(accounts.map((Account a) => a.toJson()).toList()),
  );

  /// Hashing is deliberately slow, so it goes to another isolate to keep the
  /// UI responsive. Falls back to the current isolate where `compute` isn't
  /// available.
  Future<String> _hash(String password, String salt, int iterations) async {
    final HashRequest request = HashRequest(
      password: password,
      salt: salt,
      iterations: iterations,
    );
    try {
      return await compute(hashPasswordIsolate, request);
    } on UnsupportedError {
      return hashPasswordIsolate(request);
    }
  }

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  /// Validates a would-be password, returning null when it's acceptable.
  static AuthError? validatePassword(String password, {String? confirm}) {
    if (password.length < 8) return AuthError.passwordTooShort;
    if (_commonPasswords.contains(password.toLowerCase())) {
      return AuthError.passwordTooCommon;
    }
    if (confirm != null && password != confirm) {
      return AuthError.passwordMismatch;
    }
    return null;
  }

  static bool isValidEmail(String email) =>
      _emailPattern.hasMatch(normalizeEmail(email));

  /// Creates an account and signs it in.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? confirmPassword,
  }) async {
    final String cleanName = name.trim();
    final String cleanEmail = normalizeEmail(email);

    if (cleanName.isEmpty) throw const AuthException(AuthError.nameRequired);
    if (!isValidEmail(cleanEmail)) {
      throw const AuthException(AuthError.emailInvalid);
    }
    final AuthError? passwordProblem = validatePassword(
      password,
      confirm: confirmPassword,
    );
    if (passwordProblem != null) throw AuthException(passwordProblem);

    final List<Account> accounts = _accounts();
    if (accounts.any((Account a) => a.email == cleanEmail)) {
      throw const AuthException(AuthError.emailTaken);
    }

    state = AuthState(account: state.account, busy: true);
    try {
      final String salt = PasswordHasher.newSalt();
      final String hash = await _hash(
        password,
        salt,
        PasswordHasher.iterations,
      );
      final Account account = Account(
        id: 'acct-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
        email: cleanEmail,
        name: cleanName,
        salt: salt,
        hash: hash,
        iterations: PasswordHasher.iterations,
        createdAt: DateTime.now(),
      );

      await _writeAccounts(<Account>[...accounts, account]);
      await _prefs.setString(_sessionKey, account.id);
      state = AuthState(account: account);
    } on Object {
      state = AuthState(account: state.account);
      rethrow;
    }
  }

  /// Verifies credentials and starts a session.
  Future<void> signIn({required String email, required String password}) async {
    final String cleanEmail = normalizeEmail(email);
    state = AuthState(account: state.account, busy: true);
    try {
      Account? match;
      for (final Account a in _accounts()) {
        if (a.email == cleanEmail) {
          match = a;
          break;
        }
      }

      if (match == null) {
        // Hash anyway so a missing account doesn't return noticeably faster
        // than a wrong password, which would leak which emails exist.
        await _hash(password, PasswordHasher.newSalt(), 1000);
        throw const AuthException(AuthError.credentialsWrong);
      }

      final String candidate = await _hash(
        password,
        match.salt,
        match.iterations,
      );
      if (!PasswordHasher.matches(candidate, match.hash)) {
        throw const AuthException(AuthError.credentialsWrong);
      }

      await _prefs.setString(_sessionKey, match.id);
      state = AuthState(account: match);
    } on Object {
      state = AuthState(account: state.account);
      rethrow;
    }
  }

  /// Ends the session. The account and everything the shopper saved stays.
  Future<void> signOut() async {
    await _prefs.remove(_sessionKey);
    state = const AuthState();
  }

  Future<void> updateName(String name) async {
    final Account? current = state.account;
    final String clean = name.trim();
    if (current == null || clean.isEmpty) return;

    final List<Account> next = <Account>[
      for (final Account a in _accounts())
        if (a.id == current.id) a.copyWith(name: clean) else a,
    ];
    await _writeAccounts(next);
    state = AuthState(account: current.copyWith(name: clean));
  }

  /// Deletes the signed-in account. Orders, bag and wishlist are separate and
  /// are left alone — Settings → Reset everything handles those.
  Future<void> deleteAccount() async {
    final Account? current = state.account;
    if (current == null) return;
    await _writeAccounts(<Account>[
      for (final Account a in _accounts())
        if (a.id != current.id) a,
    ]);
    await _prefs.remove(_sessionKey);
    state = const AuthState();
  }
}

final NotifierProvider<AuthNotifier, AuthState> authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience for the many widgets that only care whether someone is in.
final Provider<bool> signedInProvider = Provider<bool>(
  (Ref ref) => ref.watch(authProvider).signedIn,
);
