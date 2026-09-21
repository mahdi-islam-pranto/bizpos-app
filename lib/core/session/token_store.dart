import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The token in the platform keystore: Keychain on iOS,
/// EncryptedSharedPreferences on Android. The server keeps only a hash of it and
/// will never show it again, so losing it means signing in again.
///
/// Every read and write is wrapped. Secure storage on Android can throw after a
/// backup restore or a keystore reset, and a POS app that crashes on launch
/// because of that is far worse than one that asks for a password. A failed read
/// therefore means *signed out*, never a crash.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              // v11 encrypts with AES-GCM unconditionally. `resetOnError`
              // (on by default) drops an unreadable entry instead of throwing,
              // which is the behaviour we want after a keystore reset.
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const _tokenKey = 'bizpos.token';
  static const _expiresKey = 'bizpos.token.expiresAt';

  final FlutterSecureStorage _storage;

  Future<String?> read() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      return (token == null || token.isEmpty) ? null : token;
    } catch (e) {
      developer.log('could not read the stored token: $e', name: 'session');
      await clear();
      return null;
    }
  }

  Future<DateTime?> readExpiry() async {
    try {
      final raw = await _storage.read(key: _expiresKey);
      return raw == null ? null : DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String token, {DateTime? expiresAt}) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      if (expiresAt != null) {
        await _storage.write(
          key: _expiresKey,
          value: expiresAt.toIso8601String(),
        );
      } else {
        await _storage.delete(key: _expiresKey);
      }
    } catch (e) {
      // The session still works for this run; it just will not survive a
      // restart. Better than refusing to sign in at all.
      developer.log('could not store the token: $e', name: 'session');
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _expiresKey);
    } catch (e) {
      developer.log('could not clear the token: $e', name: 'session');
    }
  }
}
