import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// A locally-stored account.
///
/// **This is a demo, not an identity provider.** Accounts live only on this
/// device and there is no server, no email verification and no recovery. The
/// password is still never stored — only a PBKDF2 hash — because writing a
/// plaintext password to disk would be wrong even in a demo, and people reuse
/// passwords.
@immutable
class Account {
  const Account({
    required this.id,
    required this.email,
    required this.name,
    required this.salt,
    required this.hash,
    required this.iterations,
    required this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String,
    salt: json['salt'] as String,
    hash: json['hash'] as String,
    iterations: json['iterations'] as int? ?? PasswordHasher.iterations,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;

  /// Always stored lower-cased and trimmed, so sign-in isn't case sensitive.
  final String email;

  final String name;

  /// Base64 random salt, unique per account.
  final String salt;

  /// Base64 PBKDF2-HMAC-SHA256 digest.
  final String hash;

  /// Recorded per account so the cost can be raised later without locking
  /// existing users out.
  final int iterations;

  final DateTime createdAt;

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  String get firstName {
    final int space = name.indexOf(' ');
    return space > 0 ? name.substring(0, space) : name;
  }

  Account copyWith({
    String? name,
    String? salt,
    String? hash,
    int? iterations,
  }) => Account(
    id: id,
    email: email,
    name: name ?? this.name,
    salt: salt ?? this.salt,
    hash: hash ?? this.hash,
    iterations: iterations ?? this.iterations,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'email': email,
    'name': name,
    'salt': salt,
    'hash': hash,
    'iterations': iterations,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// PBKDF2-HMAC-SHA256, implemented directly so the app doesn't depend on a
/// native crypto plugin it can't run on desktop.
abstract final class PasswordHasher {
  /// Deliberately expensive: this is the only thing standing between a stolen
  /// preferences file and the user's password.
  static const int iterations = 120000;
  static const int _keyLength = 32;
  static const int _saltLength = 16;

  static String newSalt() {
    final Random random = Random.secure();
    final Uint8List bytes = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Encode(bytes);
  }

  /// Derives a key. Runs on whatever isolate calls it — callers should push
  /// this off the UI thread.
  static String derive({
    required String password,
    required String salt,
    int iterations = iterations,
  }) {
    final Hmac hmac = Hmac(sha256, utf8.encode(password));
    final Uint8List saltBytes = base64Decode(salt);
    final Uint8List out = Uint8List(_keyLength);
    int offset = 0;
    int block = 1;

    while (offset < _keyLength) {
      // U1 = PRF(password, salt || INT_32_BE(block))
      final Uint8List blockIndex = Uint8List(4)
        ..[0] = (block >> 24) & 0xff
        ..[1] = (block >> 16) & 0xff
        ..[2] = (block >> 8) & 0xff
        ..[3] = block & 0xff;

      List<int> u = hmac.convert(<int>[...saltBytes, ...blockIndex]).bytes;
      final List<int> acc = List<int>.from(u);

      for (int i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (int j = 0; j < acc.length; j++) {
          acc[j] ^= u[j];
        }
      }

      final int take = (_keyLength - offset).clamp(0, acc.length);
      out.setRange(offset, offset + take, acc);
      offset += take;
      block++;
    }
    return base64Encode(out);
  }

  /// Compares in constant time so a timing side-channel can't reveal how much
  /// of a guessed hash was correct.
  static bool matches(String a, String b) {
    final List<int> x = utf8.encode(a);
    final List<int> y = utf8.encode(b);
    if (x.length != y.length) return false;
    int diff = 0;
    for (int i = 0; i < x.length; i++) {
      diff |= x[i] ^ y[i];
    }
    return diff == 0;
  }
}

/// Arguments for the isolate entry point below.
@immutable
class HashRequest {
  const HashRequest({
    required this.password,
    required this.salt,
    required this.iterations,
  });

  final String password;
  final String salt;
  final int iterations;
}

/// Top-level so it can be handed to `compute`.
String hashPasswordIsolate(HashRequest request) => PasswordHasher.derive(
  password: request.password,
  salt: request.salt,
  iterations: request.iterations,
);
