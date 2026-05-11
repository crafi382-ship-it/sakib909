enum MessageType { text, image, video, audio, pdf, document, deleted }

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String chatRoomId;
  final String message;
  final MessageType messageType;
  final String? fileUrl;
  final String? fileName;
  final bool isSeen;
  final bool isDeleted;
  final bool isDeletedForEveryone;
  final String? replyToMessageId;
  final String? replyToMessage;
  final DateTime createdAt;
  final bool isPending;
  final bool isFailed;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.chatRoomId,
    required this.message,
    this.messageType = MessageType.text,
    this.fileUrl,
    this.fileName,
    this.isSeen = false,
    this.isDeleted = false,
    this.isDeletedForEveryone = false,
    this.replyToMessageId,
    this.replyToMessage,
    required this.createdAt,
    this.isPending = false,
    this.isFailed = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] ?? '',
        senderId: json['sender_id'] ?? '',
        receiverId: json['receiver_id'] ?? '',
        chatRoomId: json['chat_room_id'] ?? '',
        message: json['message'] ?? '',
        messageType: _parse(json['message_type']),
        fileUrl: json['file_url'],
        fileName: json['file_name'],
        isSeen: json['is_seen'] ?? false,
        isDeleted: json['is_deleted'] ?? false,
        isDeletedForEveryone: json['is_deleted_for_everyone'] ?? false,
        replyToMessageId: json['reply_to_message_id'],
        replyToMessage: json['reply_to_message'],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isPending: json['is_pending'] ?? false,
        isFailed: json['is_failed'] ?? false,
      );

  static MessageType _parse(String? t) {
    switch (t) {
      case 'image': return MessageType.image;
      case 'video': return MessageType.video;
      case 'audio': return MessageType.audio;
      case 'pdf': return MessageType.pdf;
      case 'document': return MessageType.document;
      case 'deleted': return MessageType.deleted;
      default: return MessageType.text;
    }
  }

  String get messageTypeString {
    switch (messageType) {
      case MessageType.image: return 'image';
      case MessageType.video: return 'video';
      case MessageType.audio: return 'audio';
      case MessageType.pdf: return 'pdf';
      case MessageType.document: return 'document';
      case MessageType.deleted: return 'deleted';
      default: return 'text';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'chat_room_id': chatRoomId,
        'message': message,
        'message_type': messageTypeString,
        'file_url': fileUrl,
        'file_name': fileName,
        'is_seen': isSeen,
        'is_deleted': isDeleted,
        'is_deleted_for_everyone': isDeletedForEveryone,
        'reply_to_message_id': replyToMessageId,
        'reply_to_message': replyToMessage,
        'created_at': createdAt.toIso8601String(),
        'is_pending': isPending,
        'is_failed': isFailed,
      };

  MessageModel copyWith({
    bool? isSeen,
    bool? isDeleted,
    bool? isDeletedForEveryone,
    String? message,
    MessageType? messageType,
    bool? isPending,
    bool? isFailed,
  }) =>
      MessageModel(
        id: id,
        senderId: senderId,
        receiverId: receiverId,
        chatRoomId: chatRoomId,
        message: message ?? this.message,
        messageType: messageType ?? this.messageType,
        fileUrl: fileUrl,
        fileName: fileName,
        isSeen: isSeen ?? this.isSeen,
        isDeleted: isDeleted ?? this.isDeleted,
        isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
        replyToMessageId: replyToMessageId,
        replyToMessage: replyToMessage,
        createdAt: createdAt,
        isPending: isPending ?? this.isPending,
        isFailed: isFailed ?? this.isFailed,
      );
}
