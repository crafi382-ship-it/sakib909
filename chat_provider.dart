import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();
  final LocalStorageService _localStorage = LocalStorageService();
  final NotificationService _notif = NotificationService();

  List<ChatRoomModel> _chatRooms = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isOffline = false;
  String? _errorMessage;

  List<ChatRoomModel> get chatRooms => _chatRooms;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;

  ChatProvider() {
    Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = _isOffline;
      _isOffline = results.every((r) => r == ConnectivityResult.none);
      notifyListeners();
      if (wasOffline && !_isOffline) _flushPendingMessages();
    });
  }

  Future<void> loadChatRooms(String userId) async {
    _isLoading = true;
    notifyListeners();
    final cached = _localStorage.getCachedChatRooms(userId);
    if (cached.isNotEmpty && _chatRooms.isEmpty) {
      _chatRooms = cached.map((r) => ChatRoomModel.fromJson(r)).toList();
      _isLoading = false;
      notifyListeners();
    }
    try {
      _chatRooms = await _chatService.getChatRooms(userId);
      await _localStorage.cacheChatRooms(userId, _chatRooms.map((r) => r.toJson()).toList());
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatRoomModel?> openChat(String currentUserId, UserModel otherUser) async {
    try {
      final room = await _chatService.getOrCreateChatRoom(currentUserId, otherUser.id);
      room.otherUser = otherUser;
      notifyListeners();
      return room;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMessages(String chatRoomId, String userId) async {
    _isLoading = true;
    notifyListeners();
    final cached = _localStorage.getCachedMessages(chatRoomId);
    if (cached.isNotEmpty) {
      _messages = cached.map((m) => MessageModel.fromJson(m)).toList();
      _isLoading = false;
      notifyListeners();
    }
    _injectPending(chatRoomId);
    try {
      _messages = await _chatService.getMessages(chatRoomId, userId);
      await _chatService.markMessagesAsSeen(chatRoomId, userId);
      await _localStorage.cacheMessages(chatRoomId, _messages.map((m) => m.toJson()).toList());
    } catch (_) {}
    finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void subscribeToMessages(String chatRoomId, String userId) {
    _chatService.subscribeToMessages(
      chatRoomId: chatRoomId,
      currentUserId: userId,
      onNewMessage: (msg) {
        if (_messages.any((m) => m.id == msg.id)) return;
        _messages.add(msg);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _chatService.markMessagesAsSeen(chatRoomId, userId);
        _localStorage.addMessageToCache(chatRoomId, msg.toJson());
        notifyListeners();
      },
      onUpdatedMessage: (msg) {
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx >= 0) {
          _messages[idx] = msg;
          _localStorage.updateMessageInCache(chatRoomId, msg.id, msg.toJson());
          notifyListeners();
        }
      },
    );
  }

  void subscribeToTyping(String chatRoomId, String otherUserId) {
    _chatService.subscribeToTyping(
      chatRoomId: chatRoomId,
      otherUserId: otherUserId,
      onTypingChanged: (typing) { _isTyping = typing; notifyListeners(); },
    );
  }

  void unsubscribeMessages() {
    _chatService.unsubscribeMessages();
    _chatService.unsubscribeTyping();
  }

  void updateTypingStatus(String chatRoomId, String userId, bool isTyping) =>
      _chatService.updateTypingStatus(chatRoomId, userId, isTyping);

  Future<UserModel?> searchUserByCode(String code) =>
      _chatService.searchUserByCode(code);

  Future<void> deleteMessageForMe(String messageId) async {
    await _chatService.deleteMessageForMe(messageId);
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

  Future<void> deleteMessageForEveryone(String messageId) async {
    await _chatService.deleteMessageForEveryone(messageId);
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx >= 0) {
      _messages[idx] = _messages[idx].copyWith(
        isDeletedForEveryone: true,
        message: 'This message was deleted',
        messageType: MessageType.deleted,
      );
      notifyListeners();
    }
  }

  Future<void> sendTextMessage({
    required String senderId,
    required String receiverId,
    required String chatRoomId,
    required String message,
    String? replyToMessageId,
    String? replyToMessage,
    String? receiverPlayerId,
    String? senderName,
    String? senderImageUrl,
  }) async {
    final localId = const Uuid().v4();
    final optimistic = MessageModel(
      id: localId, senderId: senderId, receiverId: receiverId,
      chatRoomId: chatRoomId, message: message, createdAt: DateTime.now(),
      replyToMessageId: replyToMessageId, replyToMessage: replyToMessage,
      isPending: true,
    );
    _messages.add(optimistic);
    notifyListeners();

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.every((r) => r == ConnectivityResult.none)) {
      await _localStorage.addPendingMessage({
        'local_id': localId, 'sender_id': senderId, 'receiver_id': receiverId,
        'chat_room_id': chatRoomId, 'message': message, 'message_type': 'text',
        'reply_to_message_id': replyToMessageId, 'reply_to_message': replyToMessage,
        'created_at': DateTime.now().toIso8601String(),
        'receiver_player_id': receiverPlayerId,
        'sender_name': senderName, 'sender_image_url': senderImageUrl,
      });
      return;
    }

    try {
      final sent = await _chatService.sendMessage(
        senderId: senderId, receiverId: receiverId, chatRoomId: chatRoomId,
        message: message, replyToMessageId: replyToMessageId, replyToMessage: replyToMessage,
      );
      final idx = _messages.indexWhere((m) => m.id == localId);
      if (idx >= 0) _messages[idx] = sent;
      await _localStorage.addMessageToCache(chatRoomId, sent.toJson());
      notifyListeners();
      if (receiverPlayerId != null && receiverPlayerId.isNotEmpty) {
        await _notif.sendMessageNotification(
          targetPlayerId: receiverPlayerId, senderName: senderName ?? 'Someone',
          chatRoomId: chatRoomId, messageText: message, messageType: 'text',
          senderImageUrl: senderImageUrl,
        );
      }
    } catch (e) {
      final idx = _messages.indexWhere((m) => m.id == localId);
      if (idx >= 0) {
        _messages[idx] = optimistic.copyWith(isFailed: true, isPending: false);
        notifyListeners();
      }
    }
  }

  Future<void> sendFileMessage({
    required String senderId,
    required String receiverId,
    required String chatRoomId,
    required File file,
    required MessageType messageType,
    String? fileName,
    String? receiverPlayerId,
    String? senderName,
    String? senderImageUrl,
  }) async {
    try {
      final fileUrl = await _storageService.uploadChatFile(file, chatRoomId);
      final name = fileName ?? file.path.split('/').last;
      final msg = _typeMsg(messageType);
      final sent = await _chatService.sendMessage(
        senderId: senderId, receiverId: receiverId, chatRoomId: chatRoomId,
        message: msg, messageType: messageType, fileUrl: fileUrl, fileName: name,
      );
      _messages.add(sent);
      await _localStorage.addMessageToCache(chatRoomId, sent.toJson());
      notifyListeners();
      if (receiverPlayerId != null && receiverPlayerId.isNotEmpty) {
        await _notif.sendMessageNotification(
          targetPlayerId: receiverPlayerId, senderName: senderName ?? 'Someone',
          chatRoomId: chatRoomId, messageText: msg, messageType: sent.messageTypeString,
          fileUrl: fileUrl, fileName: name, senderImageUrl: senderImageUrl,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  String _typeMsg(MessageType t) {
    switch (t) {
      case MessageType.image: return '📷 Photo';
      case MessageType.video: return '🎥 Video';
      case MessageType.audio: return '🎵 Audio';
      case MessageType.pdf: return '📄 PDF';
      default: return '📎 Document';
    }
  }

  Future<void> _flushPendingMessages() async {
    final pending = _localStorage.getPendingMessages();
    for (final msg in pending) {
      try {
        final sent = await _chatService.sendMessage(
          senderId: msg['sender_id'] as String,
          receiverId: msg['receiver_id'] as String,
          chatRoomId: msg['chat_room_id'] as String,
          message: msg['message'] as String,
          replyToMessageId: msg['reply_to_message_id'] as String?,
          replyToMessage: msg['reply_to_message'] as String?,
        );
        await _localStorage.removePendingMessage(msg['local_id'] as String);
        final idx = _messages.indexWhere((m) => m.id == msg['local_id']);
        if (idx >= 0) _messages[idx] = sent;
      } catch (_) {}
    }
    notifyListeners();
  }

  void _injectPending(String chatRoomId) {
    for (final p in _localStorage
        .getPendingMessages()
        .where((m) => m['chat_room_id'] == chatRoomId)) {
      if (!_messages.any((m) => m.id == p['local_id'])) {
        _messages.add(MessageModel(
          id: p['local_id'] as String,
          senderId: p['sender_id'] as String,
          receiverId: p['receiver_id'] as String,
          chatRoomId: chatRoomId,
          message: p['message'] as String,
          isPending: true,
          createdAt: DateTime.tryParse(p['created_at'] as String? ?? '') ?? DateTime.now(),
        ));
      }
    }
  }
}
