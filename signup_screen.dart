import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscure2 = true;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    final prov = context.read<AuthProvider>();
    final ok = await prov.signUp(_email.text.trim(), _pass.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OtpScreen(email: _email.text.trim())));
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
          const SizedBox(height: 48),
          const Icon(Icons.person_add_rounded, size: 72, color: Colors.white),
          const SizedBox(height: 16),
          const Text('Create Account',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Join the conversation today',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 36),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              child: Form(
                key: _form,
                child: ListView(children: [
                  const Text('Sign Up',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111B21))),
                  const SizedBox(height: 4),
                  const Text('Fill in your details to get started',
                      style: TextStyle(color: Color(0xFF8696A0), fontSize: 14)),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.mail_outline_rounded, color: Color(0xFF54656F)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v?.contains('@') ?? false) ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pass,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF54656F)),
                      suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                              color: const Color(0xFF54656F)),
                          onPressed: () => setState(() => _obscure = !_obscure)),
                    ),
                    validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Minimum 6 characters',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure2,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF54656F)),
                      suffixIcon: IconButton(
                          icon: Icon(_obscure2
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                              color: const Color(0xFF54656F)),
                          onPressed: () => setState(() => _obscure2 = !_obscure2)),
                    ),
                    validator: (v) => v == _pass.text ? null : 'Passwords do not match',
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _register,
                      child: auth.isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Already have an account? ',
                        style: TextStyle(color: Color(0xFF8696A0))),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text('Sign In',
                          style: TextStyle(
                              color: Color(0xFF25D366), fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
