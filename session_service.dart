import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Persists authentication credentials and user profile securely
/// so the user is NEVER logged out unless they explicitly sign out.
class SessionService {
  static final SessionService _i = SessionService._();
  factory SessionService() => _i;
  SessionService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyEmail = 'session_email';
  static const _keyPassword = 'session_password';
  static const _keyUser = 'cached_user';
  static const _keyLoggedIn = 'is_logged_in';

  // --------------- Credential persistence ---------------

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
  }

  Future<({String email, String password})?> loadCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
  }

  // --------------- User profile cache ---------------

  Future<void> cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<UserModel?> loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateCachedUser(UserModel user) => cacheUser(user);

  Future<void> clearCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }

  Future<bool> get hasSession async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }
}
