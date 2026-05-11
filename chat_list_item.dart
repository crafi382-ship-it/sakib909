import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/chat_room_model.dart';
import 'user_avatar.dart';

class ChatListItem extends StatelessWidget {
  final ChatRoomModel chatRoom;
  final VoidCallback onTap;
  const ChatListItem({super.key, required this.chatRoom, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final other = chatRoom.otherUser;
    final hasUnread = chatRoom.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: other?.profileImage,
              name: other?.username ?? '?',
              radius: 28,
              showOnline: true,
              isOnline: other?.isOnline ?? false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          other?.username ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF111B21),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(chatRoom.updatedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread ? const Color(0xFF25D366) : const Color(0xFF8696A0),
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chatRoom.lastMessage ?? 'Tap to say hello!',
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread
                                ? (isDark ? Colors.white70 : const Color(0xFF111B21))
                                : const Color(0xFF8696A0),
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              chatRoom.unreadCount > 99
                                  ? '99+'
                                  : chatRoom.unreadCount.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
