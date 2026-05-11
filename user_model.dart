class UserModel {
  final String id;
  final String email;
  final String username;
  final String? phoneNumber;
  final String? profileImage;
  final String userChatCode;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;
  String? oneSignalPlayerId;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.phoneNumber,
    this.profileImage,
    required this.userChatCode,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
    this.oneSignalPlayerId,
  });

  String get uid => id;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        username: json['username'] ?? '',
        phoneNumber: json['phone_number'],
        profileImage: json['profile_image'],
        userChatCode: json['user_chat_code'] ?? '',
        isOnline: json['is_online'] ?? false,
        lastSeen: json['last_seen'] != null
            ? DateTime.tryParse(json['last_seen'])
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
            : DateTime.now(),
        oneSignalPlayerId: json['onesignal_player_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'phone_number': phoneNumber,
        'profile_image': profileImage,
        'user_chat_code': userChatCode,
        'is_online': isOnline,
        'last_seen': lastSeen?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'onesignal_player_id': oneSignalPlayerId,
      };

  UserModel copyWith({
    String? username,
    String? phoneNumber,
    String? profileImage,
    bool? isOnline,
    DateTime? lastSeen,
    String? oneSignalPlayerId,
  }) =>
      UserModel(
        id: id,
        email: email,
        username: username ?? this.username,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        profileImage: profileImage ?? this.profileImage,
        userChatCode: userChatCode,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen ?? this.lastSeen,
        createdAt: createdAt,
        oneSignalPlayerId: oneSignalPlayerId ?? this.oneSignalPlayerId,
      );
}
