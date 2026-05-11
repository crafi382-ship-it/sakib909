import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_room_model.dart';
import '../widgets/chat_list_item.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    await context.read<ChatProvider>().loadChatRooms(userId);
  }

  void _openChat(ChatRoomModel room) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(chatRoom: room)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(children: [
          const Icon(Icons.chat_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          const Text('ChatApp',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 0.3)),
          if (chat.isOffline)
            Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.wifi_off_rounded, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text('Offline',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (v) {
              if (v == 'profile') Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
              if (v == 'refresh') _load();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'profile',
                  child: Row(children: [
                    Icon(Icons.person_outline_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Profile')
                  ])),
              const PopupMenuItem(
                  value: 'refresh',
                  child: Row(children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Refresh')
                  ])),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: const Color(0xFF075E54),
            child: Row(children: [
              _tabBtn(0, 'Chats'),
              _tabBtn(1, 'Status'),
              _tabBtn(2, 'Calls'),
            ]),
          ),
        ),
      ),
      body: IndexedStack(index: _tab, children: [
        _chatsTab(chat, isDark),
        _statusTab(isDark),
        _callsTab(isDark),
      ]),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF25D366),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen())),
              child: const Icon(Icons.chat_rounded, color: Colors.white),
            )
          : (_tab == 2
              ? FloatingActionButton(
                  backgroundColor: const Color(0xFF25D366),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen())),
                  child: const Icon(Icons.add_call, color: Colors.white),
                )
              : null),
    );
  }

  Widget _tabBtn(int idx, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = idx),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: _tab == idx ? Colors.white : Colors.transparent,
                      width: 2.5)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _tab == idx ? Colors.white : Colors.white60,
                fontWeight:
                    _tab == idx ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );

  Widget _chatsTab(ChatProvider chat, bool isDark) {
    if (chat.isLoading && chat.chatRooms.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF25D366)));
    }
    if (chat.chatRooms.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 52, color: Color(0xFF25D366)),
          ),
          const SizedBox(height: 20),
          const Text('No chats yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111B21))),
          const SizedBox(height: 8),
          const Text('Tap + to start a conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF8696A0), fontSize: 14, height: 1.5)),
        ]),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF25D366),
      onRefresh: _load,
      child: ListView.separated(
        itemCount: chat.chatRooms.length,
        separatorBuilder: (_, __) => const Divider(height: 0, indent: 88),
        itemBuilder: (_, i) => ChatListItem(
            chatRoom: chat.chatRooms[i],
            onTap: () => _openChat(chat.chatRooms[i])),
      ),
    );
  }

  Widget _statusTab(bool isDark) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.circle_outlined,
                size: 52, color: Color(0xFF25D366)),
          ),
          const SizedBox(height: 20),
          const Text('Status Updates',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Status feature coming soon',
              style: TextStyle(color: Color(0xFF8696A0), fontSize: 14)),
        ]),
      );

  Widget _callsTab(bool isDark) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.call_outlined,
                size: 52, color: Color(0xFF25D366)),
          ),
          const SizedBox(height: 20),
          const Text('Calls',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
              'Open any chat and tap the\ncall or video button to start a call.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF8696A0), fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen())),
            icon: const Icon(Icons.person_search_rounded),
            label: const Text('Find someone to call'),
          ),
        ]),
      );
}
