import 'user_model.dart';

class ChatRoomModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime updatedAt;
  UserModel? otherUser;
  int unreadCount;

  ChatRoomModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageType,
    required this.updatedAt,
    this.otherUser,
    this.unreadCount = 0,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) => ChatRoomModel(
        id: json['id'] ?? '',
        user1Id: json['user1'] ?? '',
        user2Id: json['user2'] ?? '',
        lastMessage: json['last_message'],
        lastMessageType: json['last_message_type'],
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user1': user1Id,
        'user2': user2Id,
        'last_message': lastMessage,
        'last_message_type': lastMessageType,
        'updated_at': updatedAt.toIso8601String(),
        if (otherUser != null) 'other_user': otherUser!.toJson(),
        'unread_count': unreadCount,
      };
}
