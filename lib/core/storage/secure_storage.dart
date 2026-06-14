import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/storage_keys.dart';

/// Wrapper around FlutterSecureStorage for token management.
/// Uses AES encryption on Android and Keychain on iOS.
class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Access Token ─────────────────────────────────────────────
  static Future<void> setAccessToken(String token) async =>
      _storage.write(key: StorageKeys.accessToken, value: token);

  static Future<String?> getAccessToken() async =>
      _storage.read(key: StorageKeys.accessToken);

  static Future<void> deleteAccessToken() async =>
      _storage.delete(key: StorageKeys.accessToken);

  // ── Refresh Token ─────────────────────────────────────────────
  static Future<void> setRefreshToken(String token) async =>
      _storage.write(key: StorageKeys.refreshToken, value: token);

  static Future<String?> getRefreshToken() async =>
      _storage.read(key: StorageKeys.refreshToken);

  static Future<void> deleteRefreshToken() async =>
      _storage.delete(key: StorageKeys.refreshToken);

  // ── Token Type ────────────────────────────────────────────────
  static Future<void> setTokenType(String type) async =>
      _storage.write(key: StorageKeys.tokenType, value: type);

  static Future<String?> getTokenType() async =>
      _storage.read(key: StorageKeys.tokenType);

  // ── Auth header ───────────────────────────────────────────────
  /// Returns the formatted Authorization header value e.g. "Bearer [token]"
  static Future<String?> getAuthHeader() async {
    final type = await getTokenType() ?? 'Bearer';
    final token = await getAccessToken();
    if (token == null) return null;
    return '$type $token';
  }

  // ── Clear all ─────────────────────────────────────────────────
  static Future<void> clearAll() async => _storage.deleteAll();

  // ── Check if authenticated ────────────────────────────────────
  static Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

/// Riverpod provider for SecureStorage (singleton-style)
final secureStorageProvider = Provider<SecureStorage>((_) => SecureStorage._());
