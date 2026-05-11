import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final prov = context.read<AuthProvider>();
    final ok = await prov.signIn(_email.text.trim(), _pass.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
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
          const Icon(Icons.chat_rounded, size: 72, color: Colors.white),
          const SizedBox(height: 14),
          const Text('ChatApp',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Connect. Chat. Share.',
              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 0.4)),
          const SizedBox(height: 36),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Form(
                key: _form,
                child: ListView(children: [
                  const Text('Welcome Back',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111B21))),
                  const SizedBox(height: 4),
                  const Text('Sign in to continue',
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
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded, color: Color(0xFF54656F)),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF54656F)),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v?.length ?? 0) >= 6 ? null : 'Minimum 6 characters',
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('Forgot Password?',
                          style: TextStyle(
                              color: Color(0xFF25D366),
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(color: Color(0xFF8696A0))),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignupScreen())),
                      child: const Text('Sign Up',
                          style: TextStyle(
                              color: Color(0xFF25D366),
                              fontWeight: FontWeight.bold)),
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
