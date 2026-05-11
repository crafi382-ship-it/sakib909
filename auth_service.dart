import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  String _generate6DigitCode() =>
      (100000 + Random().nextInt(900000)).toString();

  Future<AuthResponse> signUp({required String email, required String password}) =>
      _client.auth.signUp(email: email, password: password);

  Future<void> verifyOtp({required String email, required String token}) =>
      _client.auth.verifyOTP(email: email, token: token, type: OtpType.signup);

  Future<AuthResponse> signIn({required String email, required String password}) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Future<UserModel> createUserProfile({
    required String username,
    String? profileImageUrl,
    String? phoneNumber,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    final chatCode = _generate6DigitCode();
    final userData = {
      'id': user.id,
      'email': user.email,
      'username': username,
      'phone_number': phoneNumber,
      'profile_image': profileImageUrl,
      'user_chat_code': chatCode,
      'is_online': true,
      'last_seen': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    await _client.from(SupabaseConstants.usersTable).upsert(userData);
    return UserModel.fromJson(userData);
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final response = await _client
        .from(SupabaseConstants.usersTable)
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = currentUser;
    if (user == null) return;
    await _client.from(SupabaseConstants.usersTable).update({
      'is_online': isOnline,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }

  Future<void> updateOneSignalPlayerId(String playerId) async {
    final user = currentUser;
    if (user == null) return;
    await _client
        .from(SupabaseConstants.usersTable)
        .update({'onesignal_player_id': playerId}).eq('id', user.id);
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
