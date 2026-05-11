import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import '../constants/supabase_constants.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String> uploadProfileImage(File file) async {
    final ext = file.path.split('.').last;
    final path = 'profiles/${_uuid.v4()}.$ext';
    await _client.storage
        .from(SupabaseConstants.profileImagesBucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage
        .from(SupabaseConstants.profileImagesBucket)
        .getPublicUrl(path);
  }

  Future<String> uploadChatFile(File file, String chatRoomId) async {
    final ext = file.path.split('.').last;
    final path = '$chatRoomId/${_uuid.v4()}.$ext';
    await _client.storage
        .from(SupabaseConstants.chatFilesBucket)
        .upload(path, file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: lookupMimeType(file.path),
            ));
    return _client.storage
        .from(SupabaseConstants.chatFilesBucket)
        .getPublicUrl(path);
  }
}
