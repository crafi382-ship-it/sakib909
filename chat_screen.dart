import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/user_avatar.dart';
import 'call_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoomModel chatRoom;
  const ChatScreen({super.key, required this.chatRoom});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scroll = ScrollController();
  MessageModel? _replyTo;

  String get _myId => context.read<AuthProvider>().currentUser!.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final prov = context.read<ChatProvider>();
    await prov.loadMessages(widget.chatRoom.id, _myId);
    prov.subscribeToMessages(widget.chatRoom.id, _myId);
    prov.subscribeToTyping(
        widget.chatRoom.id, widget.chatRoom.otherUser?.id ?? '');
    _scrollToBottom();
  }

  @override
  void dispose() {
    context.read<ChatProvider>().unsubscribeMessages();
    context.read<ChatProvider>()
        .updateTypingStatus(widget.chatRoom.id, _myId, false);
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      if (animate) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
      } else {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendText(String text) async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<ChatProvider>();
    final other = widget.chatRoom.otherUser;
    await prov.sendTextMessage(
      senderId: _myId,
      receiverId: other?.id ?? '',
      chatRoomId: widget.chatRoom.id,
      message: text,
      replyToMessageId: _replyTo?.id,
      replyToMessage: _replyTo?.message,
      receiverPlayerId: other?.oneSignalPlayerId,
      senderName: auth.currentUser?.username,
      senderImageUrl: auth.currentUser?.profileImage,
    );
    setState(() => _replyTo = null);
    _scrollToBottom(animate: true);
  }

  Future<void> _sendFile(File file, MessageType type, String? name) async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<ChatProvider>();
    final other = widget.chatRoom.otherUser;
    await prov.sendFileMessage(
      senderId: _myId,
      receiverId: other?.id ?? '',
      chatRoomId: widget.chatRoom.id,
      file: file,
      messageType: type,
      fileName: name,
      receiverPlayerId: other?.oneSignalPlayerId,
      senderName: auth.currentUser?.username,
      senderImageUrl: auth.currentUser?.profileImage,
    );
    _scrollToBottom(animate: true);
  }

  void _startVoiceCall() {
    final me = context.read<AuthProvider>().currentUser;
    final other = widget.chatRoom.otherUser;
    if (me == null || other == null) return;
    startCall(context,
        currentUser: me, otherUser: other, isVideoCall: false);
  }

  void _startVideoCall() {
    final me = context.read<AuthProvider>().currentUser;
    final other = widget.chatRoom.otherUser;
    if (me == null || other == null) return;
    startCall(context,
        currentUser: me, otherUser: other, isVideoCall: true);
  }

  void _showOptions(MessageModel msg) {
    final isMine = msg.senderId == _myId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1F2C34)
              : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          _opt(ctx, Icons.reply_rounded, 'Reply',
              () => setState(() => _replyTo = msg)),
          if (msg.messageType == MessageType.text)
            _opt(ctx, Icons.copy_rounded, 'Copy', () {
              Clipboard.setData(ClipboardData(text: msg.message));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Copied'),
                  duration: Duration(seconds: 1)));
            }),
          _opt(ctx, Icons.delete_outline_rounded, 'Delete for me',
              () => context.read<ChatProvider>().deleteMessageForMe(msg.id),
              color: Colors.orange),
          if (isMine)
            _opt(ctx, Icons.delete_forever_rounded,
                'Delete for everyone',
                () => context
                    .read<ChatProvider>()
                    .deleteMessageForEveryone(msg.id),
                color: Colors.red),
        ]),
      ),
    );
  }

  Widget _opt(BuildContext ctx, IconData icon, String label, VoidCallback fn,
      {Color? color}) =>
      ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (color ?? const Color(0xFF25D366)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? const Color(0xFF25D366), size: 22),
        ),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w500, color: color)),
        onTap: () { Navigator.pop(ctx); fn(); },
      );

  String _lastSeen() {
    final other = widget.chatRoom.otherUser;
    if (other == null) return '';
    if (other.isOnline) return 'online';
    if (other.lastSeen == null) return 'last seen recently';
    final diff = DateTime.now().difference(other.lastSeen!);
    if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'last seen ${diff.inHours}h ago';
    return 'last seen ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prov = context.watch<ChatProvider>();
    final other = widget.chatRoom.otherUser;
    final msgs = prov.messages;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1418) : const Color(0xFFEBECF0),
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {},
          child: Row(children: [
            UserAvatar(
              imageUrl: other?.profileImage,
              name: other?.username ?? '?',
              radius: 20,
              showOnline: true,
              isOnline: other?.isOnline ?? false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(other?.username ?? 'Chat',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  Text(
                    prov.isTyping ? 'typing...' : _lastSeen(),
                    style: TextStyle(
                        fontSize: 12,
                        color: prov.isTyping
                            ? const Color(0xFF25D366)
                            : Colors.white70),
                  ),
                ],
              ),
            ),
          ]),
        ),
        actions: [
          // Voice call button
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.white),
            tooltip: 'Voice call',
            onPressed: _startVoiceCall,
          ),
          // Video call button
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.white),
            tooltip: 'Video call',
            onPressed: _startVideoCall,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: prov.isLoading && msgs.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF25D366)))
              : msgs.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black38
                              : Colors.white70,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                            'Say hello to ${other?.username ?? 'them'} 👋',
                            style: const TextStyle(fontSize: 14)),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) {
                        final msg = msgs[i];
                        final isMine = msg.senderId == _myId;
                        final showDate = i == 0 ||
                            !_sameDay(msgs[i - 1].createdAt, msg.createdAt);
                        return Column(children: [
                          if (showDate) _dateBadge(msg.createdAt, isDark),
                          ChatBubble(
                            message: msg,
                            isSentByMe: isMine,
                            onLongPress: () => _showOptions(msg),
                            onReply: () => setState(() => _replyTo = msg),
                          ),
                        ]);
                      },
                    ),
        ),
        MessageInput(
          onSendText: _sendText,
          onSendFile: _sendFile,
          onTypingChanged: (t) => context
              .read<ChatProvider>()
              .updateTypingStatus(widget.chatRoom.id, _myId, t),
          replyMessage: _replyTo,
          onCancelReply: () => setState(() => _replyTo = null),
        ),
      ]),
    );
  }

  Widget _dateBadge(DateTime date, bool isDark) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    final label = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Yesterday'
            : '${date.day}/${date.month}/${date.year}';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
          color: isDark ? Colors.black38 : Colors.white70,
          borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8696A0),
              fontWeight: FontWeight.w500)),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
