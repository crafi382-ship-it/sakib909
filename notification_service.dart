import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../constants/supabase_constants.dart';

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  void Function(String chatRoomId, String senderName)? onNotificationTapped;

  void initializeBackground() {
    try {
      OneSignal.initialize(OneSignalConstants.appId);
      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.additionalData;
        if (data != null && onNotificationTapped != null) {
          final chatRoomId = data['chat_room_id'] as String? ?? '';
          final senderName = data['sender_name'] as String? ?? '';
          if (chatRoomId.isNotEmpty) onNotificationTapped!(chatRoomId, senderName);
        }
      });
      Future.delayed(const Duration(seconds: 3),
          () => OneSignal.Notifications.requestPermission(true));
    } catch (_) {}
  }

  Future<String?> getPlayerId() async {
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (_) {
      return null;
    }
  }

  void setExternalUserId(String userId) {
    try { OneSignal.login(userId); } catch (_) {}
  }

  void logout() {
    try { OneSignal.logout(); } catch (_) {}
  }

  Future<void> sendMessageNotification({
    required String targetPlayerId,
    required String senderName,
    required String chatRoomId,
    required String messageText,
    required String messageType,
    String? fileUrl,
    String? fileName,
    String? senderImageUrl,
  }) async {
    if (targetPlayerId.isEmpty) return;
    String body;
    String? bigPicture;
    switch (messageType) {
      case 'image': body = '📷 Photo'; bigPicture = fileUrl; break;
      case 'video': body = '🎥 Video'; break;
      case 'audio': body = '🎵 Voice message'; break;
      case 'pdf': body = '📄 ${fileName ?? 'Document'}'; break;
      case 'document': body = '📎 ${fileName ?? 'File'}'; break;
      default: body = messageText;
    }
    try {
      await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${OneSignalConstants.restApiKey}',
        },
        body: jsonEncode({
          'app_id': OneSignalConstants.appId,
          'include_player_ids': [targetPlayerId],
          'headings': {'en': senderName},
          'contents': {'en': body},
          'data': {
            'chat_room_id': chatRoomId,
            'sender_name': senderName,
            'message_type': messageType,
          },
          if (bigPicture != null) 'big_picture': bigPicture,
          if (senderImageUrl != null && senderImageUrl.isNotEmpty)
            'large_icon': senderImageUrl,
          'priority': 10,
        }),
      );
    } catch (_) {}
  }
}
