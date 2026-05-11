import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../constants/supabase_constants.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final StorageService _storage = StorageService();
  final NotificationService _notif = NotificationService();
  final SessionService _session = SessionService();
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthState _status = AuthState.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  String? _pendingEmail;

  AuthState get status => _status;
  AuthState get state => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get pendingEmail => _pendingEmail;
  bool get isAuthenticated => _status == AuthState.authenticated;
  bool get isLoading => _status == AuthState.loading;

  void _set(AuthState s) { _status = s; notifyListeners(); }

  /// Called at app start. Tries Supabase session first,
  /// then falls back to saved credentials for auto-login,
  /// then falls back to cached profile for offline mode.
  Future<void> checkAuthStatus() async {
    _set(AuthState.loading);

    // 1. Try existing Supabase session
    if (_auth.isLoggedIn) {
      try {
        final user = await _auth.getUserProfile(_auth.currentUser!.id);
        if (user != null) {
          _currentUser = user;
          await _session.cacheUser(user);
          await _auth.updateOnlineStatus(true);
          await _syncOneSignal();
          _set(AuthState.authenticated);
          return;
        }
      } catch (_) {
        // Network error — try cached profile
        final cached = await _session.loadCachedUser();
        if (cached != null) {
          _currentUser = cached;
          _set(AuthState.authenticated);
          return;
        }
      }
    }

    // 2. No active session — try auto-login with saved credentials
    final creds = await _session.loadCredentials();
    if (creds != null) {
      try {
        await _auth.signIn(email: creds.email, password: creds.password);
        final user = await _auth.getUserProfile(_auth.currentUser!.id);
        if (user != null) {
          _currentUser = user;
          await _session.cacheUser(user);
          await _auth.updateOnlineStatus(true);
          await _syncOneSignal();
          _set(AuthState.authenticated);
          return;
        }
      } catch (_) {
        // Network offline — use cached profile
        final cached = await _session.loadCachedUser();
        if (cached != null) {
          _currentUser = cached;
          _set(AuthState.authenticated);
          return;
        }
      }
    }

    // 3. No session, no credentials, no cache
    _set(AuthState.unauthenticated);
  }

  Future<bool> signUp(String? email, String? password,
      {String? email2, String? password2}) async {
    final e = email ?? email2 ?? '';
    final p = password ?? password2 ?? '';
    _set(AuthState.loading);
    try {
      await _auth.signUp(email: e, password: p);
      _pendingEmail = e;
      _set(AuthState.unauthenticated);
      return true;
    } catch (ex) {
      _errorMessage = ex.toString().replaceAll('Exception: ', '');
      _set(AuthState.error);
      return false;
    }
  }

  Future<bool> signIn(String? email, String? password,
      {String? email2, String? password2}) async {
    final e = email ?? email2 ?? '';
    final p = password ?? password2 ?? '';
    _set(AuthState.loading);
    try {
      await _auth.signIn(email: e, password: p);
      final user = await _auth.getUserProfile(_auth.currentUser!.id);
      if (user != null) {
        _currentUser = user;
        // Persist credentials for permanent session
        await _session.saveCredentials(e, p);
        await _session.cacheUser(user);
        await _auth.updateOnlineStatus(true);
        await _syncOneSignal();
        _set(AuthState.authenticated);
        return true;
      }
      _set(AuthState.unauthenticated);
      return false;
    } catch (_) {
      _errorMessage = 'Invalid email or password.';
      _set(AuthState.error);
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String token) async {
    _set(AuthState.loading);
    try {
      await _auth.verifyOtp(email: email, token: token);
      _set(AuthState.unauthenticated);
      return true;
    } catch (_) {
      _errorMessage = 'Invalid or expired code. Please try again.';
      _set(AuthState.error);
      return false;
    }
  }

  Future<bool> createProfile(String username, File? imageFile,
      {String? phoneNumber}) async {
    _set(AuthState.loading);
    try {
      String? imageUrl;
      if (imageFile != null) imageUrl = await _storage.uploadProfileImage(imageFile);
      final user = await _auth.createUserProfile(
        username: username,
        profileImageUrl: imageUrl,
        phoneNumber: phoneNumber,
      );
      _currentUser = user;
      await _session.cacheUser(user);
      await _auth.updateOnlineStatus(true);
      await _syncOneSignal();
      _notif.setExternalUserId(user.id);
      _set(AuthState.authenticated);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _set(AuthState.error);
      return false;
    }
  }

  Future<void> updateProfile(String username, File? newImageFile) async {
    if (_currentUser == null) return;
    _set(AuthState.loading);
    try {
      String? imageUrl = _currentUser!.profileImage;
      if (newImageFile != null) imageUrl = await _storage.uploadProfileImage(newImageFile);
      await _supabase
          .from(SupabaseConstants.usersTable)
          .update({'username': username, 'profile_image': imageUrl})
          .eq('id', _currentUser!.id);
      _currentUser = _currentUser!.copyWith(username: username, profileImage: imageUrl);
      await _session.cacheUser(_currentUser!);
      _set(AuthState.authenticated);
    } catch (e) {
      _errorMessage = e.toString();
      _set(AuthState.error);
    }
  }

  Future<void> signOut() async {
    if (_currentUser != null) await _auth.updateOnlineStatus(false);
    _notif.logout();
    await _auth.signOut();
    await _session.clearCredentials();
    await _session.clearCachedUser();
    _currentUser = null;
    _set(AuthState.unauthenticated);
  }

  Future<void> _syncOneSignal() async {
    try {
      final id = await _notif.getPlayerId();
      if (id != null && _currentUser != null) {
        await _auth.updateOneSignalPlayerId(id);
        _notif.setExternalUserId(_currentUser!.id);
      }
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthState.error) _set(AuthState.unauthenticated);
  }
}
