import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static const _msgsBox = 'messages_cache';
  static const _pendingBox = 'pending_messages';
  static const _roomsBox = 'chat_rooms_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_msgsBox);
    await Hive.openBox<Map>(_pendingBox);
    await Hive.openBox<Map>(_roomsBox);
  }

  Future<void> cacheMessages(
      String chatRoomId, List<Map<String, dynamic>> messages) =>
      Hive.box<Map>(_msgsBox).put(chatRoomId, {
        'messages': messages,
        'cached_at': DateTime.now().toIso8601String(),
      });

  List<Map<String, dynamic>> getCachedMessages(String chatRoomId) {
    final data = Hive.box<Map>(_msgsBox).get(chatRoomId);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(
      ((data['messages'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  Future<void> addMessageToCache(
      String chatRoomId, Map<String, dynamic> message) async {
    final existing = getCachedMessages(chatRoomId);
    final idx = existing.indexWhere((m) => m['id'] == message['id']);
    if (idx >= 0) {
      existing[idx] = message;
    } else {
      existing.add(message);
      existing.sort((a, b) => (a['created_at'] as String? ?? '')
          .compareTo(b['created_at'] as String? ?? ''));
    }
    await cacheMessages(chatRoomId, existing);
  }

  Future<void> updateMessageInCache(String chatRoomId, String messageId,
      Map<String, dynamic> updates) async {
    final existing = getCachedMessages(chatRoomId);
    final idx = existing.indexWhere((m) => m['id'] == messageId);
    if (idx >= 0) {
      existing[idx] = {...existing[idx], ...updates};
      await cacheMessages(chatRoomId, existing);
    }
  }

  Future<void> addPendingMessage(Map<String, dynamic> message) =>
      Hive.box<Map>(_pendingBox).put(message['local_id'] as String, message);

  Future<void> removePendingMessage(String localId) =>
      Hive.box<Map>(_pendingBox).delete(localId);

  List<Map<String, dynamic>> getPendingMessages() =>
      Hive.box<Map>(_pendingBox)
          .values
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  Future<void> cacheChatRooms(
      String userId, List<Map<String, dynamic>> rooms) =>
      Hive.box<Map>(_roomsBox).put(userId, {
        'rooms': rooms,
        'cached_at': DateTime.now().toIso8601String(),
      });

  List<Map<String, dynamic>> getCachedChatRooms(String userId) {
    final data = Hive.box<Map>(_roomsBox).get(userId);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(
      ((data['rooms'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }
}
