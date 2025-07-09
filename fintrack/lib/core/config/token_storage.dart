// lib/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Key untuk menyimpan access token
  static const String _accessTokenKey = 'access_token';
  // Key untuk menyimpan expiration token
  static const String _expirationTokenKey = 'expiration_token';
  // Key untuk menyimpan refresh token
  static const String _refreshTokenKey = 'refresh_token';

  // Menyimpan access token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  // Mendapatkan access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // cek data
  Future<bool> hasAccessToken() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }

  // Menyimpan expiration token
  Future<void> saveExpirationToken(DateTime expiration) async {
    final expirationString = expiration.toIso8601String();
    await _storage.write(key: _expirationTokenKey, value: expirationString);
  }

  // Mendapatkan expiration token
  Future<DateTime?> getExpirationToken() async {
    final expirationString = await _storage.read(key: _expirationTokenKey);
    if (expirationString != null) {
      return DateTime.parse(expirationString);
    }
    return null;
  }

  // Menyimpan refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  // Mendapatkan refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Menghapus refresh token secara spesifik
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // Menghapus semua token
  Future<void> deleteAllTokens() async {
    await _storage.deleteAll();
  }
}
