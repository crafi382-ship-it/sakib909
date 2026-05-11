import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/user_avatar.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  File? _newImage;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
        text: context.read<AuthProvider>().currentUser?.username ?? '');
  }

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() { _newImage = File(picked.path); _editing = true; });
    }
  }

  Future<void> _save() async {
    await context.read<AuthProvider>().updateProfile(_name.text.trim(), _newImage);
    if (!mounted) return;
    setState(() { _editing = false; _newImage = null; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile updated'),
        backgroundColor: Color(0xFF25D366)));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sign Out')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_editing)
            TextButton(
              onPressed: auth.isLoading ? null : _save,
              child: const Text('Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(children: [
              _newImage != null
                  ? CircleAvatar(radius: 60, backgroundImage: FileImage(_newImage!))
                  : UserAvatar(
                      imageUrl: user?.profileImage,
                      name: user?.username ?? '?',
                      radius: 60),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                      color: Color(0xFF25D366), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 20, color: Colors.white),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 28),
        _card(isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Display Name',
              style: TextStyle(
                  color: Color(0xFF25D366),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF54656F))),
            onChanged: (_) => setState(() => _editing = true),
          ),
        ])),
        const SizedBox(height: 16),
        _card(isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Account Info',
              style: TextStyle(
                  color: Color(0xFF25D366),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _info(Icons.mail_outline_rounded, 'Email', user?.email ?? '-'),
          const Divider(height: 20),
          _info(Icons.phone_outlined, 'Phone', user?.phoneNumber ?? 'Not set'),
          const Divider(height: 20),
          _info(Icons.tag_rounded, 'Chat Code', user?.userChatCode ?? '-'),
        ])),
        const SizedBox(height: 16),
        _card(isDark, child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Row(children: [
            Icon(Icons.dark_mode_outlined, color: Color(0xFF54656F), size: 22),
            SizedBox(width: 12),
            Text('Dark Mode',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ]),
          Consumer<ThemeProvider>(
            builder: (_, t, __) => Switch(
                value: t.isDarkMode,
                onChanged: (_) => t.toggleTheme(),
                activeColor: const Color(0xFF25D366)),
          ),
        ])),
        const SizedBox(height: 16),
        _card(isDark, child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.logout_rounded, color: Colors.red[600], size: 22),
          ),
          title: Text('Sign Out',
              style: TextStyle(
                  color: Colors.red[600], fontWeight: FontWeight.w600)),
          onTap: _logout,
        )),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _card(bool isDark, {required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2C34) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );

  Widget _info(IconData icon, String label, String value) =>
      Row(children: [
        Icon(icon, color: const Color(0xFF8696A0), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF8696A0), fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
          ]),
        ),
      ]);
}
