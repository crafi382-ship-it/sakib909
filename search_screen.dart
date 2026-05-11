import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _ctrl = TextEditingController();
  List<UserModel> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); _ctrl.dispose(); super.dispose(); }

  Future<void> _findByCode() async {
    final code = _ctrl.text.trim();
    if (code.length != 6) return;
    setState(() => _loading = true);
    final user = await context.read<ChatProvider>().searchUserByCode(code);
    setState(() { _loading = false; _results = user != null ? [user] : []; });
  }

  Future<void> _openChat(UserModel user) async {
    final me = context.read<AuthProvider>().currentUser!;
    final room = await context.read<ChatProvider>().openChat(me.id, user);
    if (!mounted) return;
    if (room != null) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ChatScreen(chatRoom: room)));
    }
  }

  Widget _userTile(UserModel user) => ListTile(
        leading: UserAvatar(
            imageUrl: user.profileImage,
            name: user.username,
            radius: 26,
            showOnline: true,
            isOnline: user.isOnline),
        title: Text(user.username,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(user.email,
            style: const TextStyle(color: Color(0xFF8696A0), fontSize: 13)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(20)),
          child: const Text('Message',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
        onTap: () => _openChat(user),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'By Code'), Tab(text: 'Browse')],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        // --- By Code tab ---
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2C34) : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Find by Chat Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                    'Enter the 6-digit code of the person you want to chat with.',
                    style: TextStyle(color: Color(0xFF8696A0), fontSize: 13, height: 1.4)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        labelText: '6-Digit Code',
                        prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF54656F)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2A3942) : Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFF25D366), width: 1.5)),
                        counterText: '',
                      ),
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _findByCode(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _findByCode,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14)),
                    child: const Text('Find'),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFF25D366))),
            if (!_loading && _results.isNotEmpty) ...[
              const Text('Result',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF8696A0))),
              const SizedBox(height: 10),
              ..._results.map(_userTile),
            ],
            if (!_loading && _results.isEmpty && _ctrl.text.isNotEmpty)
              Center(
                child: Column(children: [
                  const SizedBox(height: 40),
                  Icon(Icons.person_search_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text('No user found with that code',
                      style: TextStyle(color: Color(0xFF8696A0))),
                ]),
              ),
          ]),
        ),
        // --- Browse tab ---
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.people_outline_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Share your Chat Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Consumer<AuthProvider>(builder: (_, auth, __) {
              final code = auth.currentUser?.userChatCode ?? '------';
              return Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: const Color(0xFF25D366).withOpacity(0.3)),
                  ),
                  child: Text(code,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF25D366),
                          letterSpacing: 6)),
                ),
                const SizedBox(height: 12),
                const Text('Share this code with others to chat',
                    style: TextStyle(color: Color(0xFF8696A0), fontSize: 13)),
              ]);
            }),
          ]),
        ),
      ]),
    );
  }
}
