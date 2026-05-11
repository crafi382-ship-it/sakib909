import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});
  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  File? _image;

  @override
  void dispose() { _name.dispose(); _phone.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final prov = context.read<AuthProvider>();
    final ok = await prov.createProfile(
      _name.text.trim(), _image,
      phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } else if (prov.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(prov.errorMessage!), backgroundColor: Colors.red[600]));
      prov.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 40),
          const Text('Create Profile',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Tell us about yourself',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              child: Form(
                key: _form,
                child: ListView(children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFFF0F2F5),
                          backgroundImage: _image != null ? FileImage(_image!) : null,
                          child: _image == null
                              ? const Icon(Icons.person_rounded, size: 56, color: Color(0xFF8696A0))
                              : null,
                        ),
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 36, height: 36,
                            decoration: const BoxDecoration(
                                color: Color(0xFF25D366), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                      child: Text('Tap to add photo',
                          style: TextStyle(color: Color(0xFF8696A0), fontSize: 13))),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF54656F)),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v?.trim().length ?? 0) >= 2 ? null : 'Enter at least 2 characters',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (optional)',
                      prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF54656F)),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _save,
                      child: auth.isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Continue'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
