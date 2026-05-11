import 'user_model.dart';

class ChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime updatedAt;
  final int unreadCount;
  UserModel? otherUser;

  ChatModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageType,
    required this.updatedAt,
    this.unreadCount = 0,
    this.otherUser,
  });

  String get chatRoom => id;

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
        id: json['id'] ?? '',
        user1Id: json['user1'] ?? '',
        user2Id: json['user2'] ?? '',
        lastMessage: json['last_message'],
        lastMessageType: json['last_message_type'],
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
            : DateTime.now(),
        unreadCount: json['unread_count'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user1': user1Id,
        'user2': user2Id,
        'last_message': lastMessage,
        'last_message_type': lastMessageType,
        'updated_at': updatedAt.toIso8601String(),
      };

  ChatModel copyWith({
    String? lastMessage,
    String? lastMessageType,
    DateTime? updatedAt,
    int? unreadCount,
    UserModel? otherUser,
  }) =>
      ChatModel(
        id: id,
        user1Id: user1Id,
        user2Id: user2Id,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageType: lastMessageType ?? this.lastMessageType,
        updatedAt: updatedAt ?? this.updatedAt,
        unreadCount: unreadCount ?? this.unreadCount,
        otherUser: otherUser ?? this.otherUser,
      );
}
