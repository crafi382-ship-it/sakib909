import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSentByMe;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.onLongPress,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (message.isDeletedForEveryone) return _deleted(isDark);

    final Color bubbleColor = isSentByMe
        ? (isDark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3))
        : (isDark ? const Color(0xFF1F2C34) : Colors.white);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isSentByMe ? 64 : 8,
            right: isSentByMe ? 8 : 64,
            top: 2, bottom: 2,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isSentByMe ? 18 : 4),
              bottomRight: Radius.circular(isSentByMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 1))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.replyToMessage != null) _replyPreview(),
              _content(isDark),
              _timestamp(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deleted(bool isDark) => Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
              left: isSentByMe ? 64 : 8,
              right: isSentByMe ? 8 : 64,
              top: 2, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A3942) : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isSentByMe ? 18 : 4),
              bottomRight: Radius.circular(isSentByMe ? 4 : 18),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.block, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text('This message was deleted',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic)),
          ]),
        ),
      );

  Widget _replyPreview() => Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: const Border(
              left: BorderSide(color: Color(0xFF25D366), width: 3)),
        ),
        child: Text(message.replyToMessage ?? '',
            style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      );

  Widget _content(bool isDark) {
    switch (message.messageType) {
      case MessageType.image: return _image();
      case MessageType.video: return _video();
      case MessageType.audio: return _audio(isDark);
      case MessageType.pdf:
      case MessageType.document: return _document();
      default: return _text(isDark);
    }
  }

  Widget _text(bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
        child: Text(
          message.isPending
              ? '${message.message} ⏳'
              : (message.isFailed ? '${message.message} ❌' : message.message),
          style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF111B21),
              height: 1.4),
        ),
      );

  Widget _image() => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: GestureDetector(
          onTap: () => _open(message.fileUrl ?? ''),
          child: CachedNetworkImage(
            imageUrl: message.fileUrl ?? '',
            width: 240, height: 240, fit: BoxFit.cover,
            placeholder: (_, __) => Container(
                width: 240, height: 240, color: Colors.grey[200],
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))),
            errorWidget: (_, __, ___) => Container(
                width: 240, height: 120, color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
      );

  Widget _video() => GestureDetector(
        onTap: () => _open(message.fileUrl ?? ''),
        child: Container(
          width: 240, height: 160,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14)),
          child: const Stack(alignment: Alignment.center, children: [
            Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
            Positioned(
                bottom: 8, left: 10,
                child: Text('Video',
                    style: TextStyle(color: Colors.white70, fontSize: 12))),
          ]),
        ),
      );

  Widget _audio(bool isDark) => Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          GestureDetector(
            onTap: () => _open(message.fileUrl ?? ''),
            child: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(
                  color: Color(0xFF25D366), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                height: 3,
                decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 5),
            Text(message.fileName ?? 'Audio',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54),
                overflow: TextOverflow.ellipsis),
          ])),
        ]),
      );

  Widget _document() => GestureDetector(
        onTap: () => _open(message.fileUrl ?? ''),
        child: Container(
          width: 220, padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: message.messageType == MessageType.pdf
                    ? Colors.red[50]
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                message.messageType == MessageType.pdf
                    ? Icons.picture_as_pdf
                    : Icons.insert_drive_file,
                color: message.messageType == MessageType.pdf
                    ? Colors.red[600]
                    : Colors.blue[600],
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message.fileName ?? 'Document',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis, maxLines: 2)),
          ]),
        ),
      );

  Widget _timestamp(bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 10, 7),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            DateFormat('HH:mm').format(message.createdAt.toLocal()),
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38),
          ),
          if (isSentByMe) ...[
            const SizedBox(width: 4),
            Icon(
              message.isSeen ? Icons.done_all : Icons.done,
              size: 15,
              color: message.isSeen
                  ? const Color(0xFF34B7F1)
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ],
        ]),
      );

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
