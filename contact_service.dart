import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/user_model.dart';

class ContactService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<String>> getDevicePhoneNumbers() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) return [];
    final contacts =
        await FlutterContacts.getContacts(withProperties: true);
    final numbers = <String>{};
    for (final c in contacts) {
      for (final p in c.phones) {
        final n = p.number.replaceAll(RegExp(r'\D'), '');
        if (n.length >= 7) numbers.add(n);
      }
    }
    return numbers.toList();
  }

  Future<List<UserModel>> searchUsers(
      String query, String currentUserId) async {
    if (query.trim().length < 2) return [];
    try {
      final byName = await _client
          .from(SupabaseConstants.usersTable)
          .select()
          .ilike('username', '%$query%')
          .neq('id', currentUserId)
          .limit(20);
      final all = <String, UserModel>{};
      for (final row in (byName as List)) {
        final u = UserModel.fromJson(row);
        all[u.id] = u;
      }
      return all.values.toList();
    } catch (_) {
      return [];
    }
  }
}
