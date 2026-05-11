import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/message_model.dart';
import '../models/chat_room_model.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _messageChannel;
  RealtimeChannel? _typingChannel;

  Future<UserModel?> searchUserByCode(String chatCode) async {
    final response = await _client
        .from(SupabaseConstants.usersTable)
        .select()
        .eq('user_chat_code', chatCode)
        .maybeSingle();
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<ChatRoomModel> getOrCreateChatRoom(String userId1, String userId2) async {
    final existing = await _client
        .from(SupabaseConstants.chatRoomsTable)
        .select()
        .or('and(user1.eq.$userId1,user2.eq.$userId2),'
            'and(user1.eq.$userId2,user2.eq.$userId1)')
        .maybeSingle();
    if (existing != null) return ChatRoomModel.fromJson(existing);
    final newRoom = await _client
        .from(SupabaseConstants.chatRoomsTable)
        .insert({
          'user1': userId1,
          'user2': userId2,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return ChatRoomModel.fromJson(newRoom);
  }

  Future<List<ChatRoomModel>> getChatRooms(String userId) async {
    final response = await _client
        .from(SupabaseConstants.chatRoomsTable)
        .select()
        .or('user1.eq.$userId,user2.eq.$userId')
        .order('updated_at', ascending: false);
    final rooms = (response as List).map((r) => ChatRoomModel.fromJson(r)).toList();
    for (var room in rooms) {
      final otherId = room.user1Id == userId ? room.user2Id : room.user1Id;
      final userResp = await _client
          .from(SupabaseConstants.usersTable)
          .select()
          .eq('id', otherId)
          .maybeSingle();
      if (userResp != null) room.otherUser = UserModel.fromJson(userResp);
      final unread = await _client
          .from(SupabaseConstants.chatsTable)
          .select()
          .eq('chat_room_id', room.id)
          .eq('receiver_id', userId)
          .eq('is_seen', false)
          .eq('is_deleted_for_everyone', false);
      room.unreadCount = (unread as List).length;
    }
    return rooms;
  }

  Future<List<ChatModel>> getUserChats(String userId) async {
    final response = await _client
        .from(SupabaseConstants.chatRoomsTable)
        .select()
        .or('user1.eq.$userId,user2.eq.$userId')
        .order('updated_at', ascending: false);
    final chats = <ChatModel>[];
    for (final r in (response as List)) {
      final chat = ChatModel.fromJson(r);
      final otherId = chat.user1Id == userId ? chat.user2Id : chat.user1Id;
      final userResp = await _client
          .from(SupabaseConstants.usersTable)
          .select()
          .eq('id', otherId)
          .maybeSingle();
      if (userResp != null) chat.otherUser = UserModel.fromJson(userResp);
      final unread = await _client
          .from(SupabaseConstants.chatsTable)
          .select()
          .eq('chat_room_id', chat.id)
          .eq('receiver_id', userId)
          .eq('is_seen', false);
      chats.add(chat.copyWith(unreadCount: (unread as List).length));
    }
    return chats;
  }

  Future<List<MessageModel>> getMessages(String chatRoomId, String userId) async {
    final response = await _client
        .from(SupabaseConstants.chatsTable)
        .select()
        .eq('chat_room_id', chatRoomId)
        .order('created_at', ascending: true);
    return (response as List)
        .map((m) => MessageModel.fromJson(m))
        .where((m) => !(m.isDeleted && m.senderId == userId))
        .toList();
  }

  void subscribeToMessages({
    required String chatRoomId,
    required String currentUserId,
    required void Function(MessageModel) onNewMessage,
    required void Function(MessageModel) onUpdatedMessage,
  }) {
    _messageChannel?.unsubscribe();
    _messageChannel = _client
        .channel('messages:$chatRoomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConstants.chatsTable,
          callback: (payload) {
            try {
              final msg = MessageModel.fromJson(
                  payload.newRecord as Map<String, dynamic>);
              if (msg.chatRoomId != chatRoomId) return;
              onNewMessage(msg);
            } catch (_) {}
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConstants.chatsTable,
          callback: (payload) {
            try {
              final msg = MessageModel.fromJson(
                  payload.newRecord as Map<String, dynamic>);
              if (msg.chatRoomId != chatRoomId) return;
              onUpdatedMessage(msg);
            } catch (_) {}
          },
        )
        .subscribe();
  }

  void unsubscribeMessages() {
    _messageChannel?.unsubscribe();
    _messageChannel = null;
  }

  Future<MessageModel> sendMessage({
    required String senderId,
    required String receiverId,
    required String chatRoomId,
    required String message,
    MessageType messageType = MessageType.text,
    String? fileUrl,
    String? fileName,
    String? replyToMessageId,
    String? replyToMessage,
  }) async {
    final data = {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'chat_room_id': chatRoomId,
      'message': message,
      'message_type': _typeStr(messageType),
      'file_url': fileUrl,
      'file_name': fileName,
      'is_seen': false,
      'is_deleted': false,
      'is_deleted_for_everyone': false,
      'reply_to_message_id': replyToMessageId,
      'reply_to_message': replyToMessage,
      'created_at': DateTime.now().toIso8601String(),
    };
    final response = await _client
        .from(SupabaseConstants.chatsTable)
        .insert(data)
        .select()
        .single();
    final preview = messageType == MessageType.text
        ? message
        : '📎 ${_typeStr(messageType)}';
    await _client.from(SupabaseConstants.chatRoomsTable).update({
      'last_message': preview,
      'last_message_type': _typeStr(messageType),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', chatRoomId);
    return MessageModel.fromJson(response);
  }

  String _typeStr(MessageType t) {
    switch (t) {
      case MessageType.image: return 'image';
      case MessageType.video: return 'video';
      case MessageType.audio: return 'audio';
      case MessageType.pdf: return 'pdf';
      case MessageType.document: return 'document';
      default: return 'text';
    }
  }

  Future<void> markMessagesAsSeen(String chatRoomId, String receiverId) =>
      _client
          .from(SupabaseConstants.chatsTable)
          .update({'is_seen': true})
          .eq('chat_room_id', chatRoomId)
          .eq('receiver_id', receiverId)
          .eq('is_seen', false);

  Future<void> deleteMessageForMe(String messageId) =>
      _client.from(SupabaseConstants.chatsTable)
          .update({'is_deleted': true}).eq('id', messageId);

  Future<void> deleteMessageForEveryone(String messageId) =>
      _client.from(SupabaseConstants.chatsTable).update({
        'is_deleted_for_everyone': true,
        'message': 'This message was deleted',
        'message_type': 'deleted',
        'file_url': null,
      }).eq('id', messageId);

  Future<void> updateTypingStatus(
          String chatRoomId, String userId, bool isTyping) =>
      _client.from('typing_status').upsert({
        'chat_room_id': chatRoomId,
        'user_id': userId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });

  void subscribeToTyping({
    required String chatRoomId,
    required String otherUserId,
    required void Function(bool) onTypingChanged,
  }) {
    _typingChannel?.unsubscribe();
    _typingChannel = _client
        .channel('typing:$chatRoomId:$otherUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'typing_status',
          callback: (payload) {
            try {
              final record =
                  payload.newRecord as Map<String, dynamic>? ?? {};
              if (record['chat_room_id'] != chatRoomId) return;
              if (record['user_id'] == otherUserId) {
                onTypingChanged(record['is_typing'] as bool? ?? false);
              }
            } catch (_) {}
          },
        )
        .subscribe();
  }

  void unsubscribeTyping() {
    _typingChannel?.unsubscribe();
    _typingChannel = null;
  }
}
