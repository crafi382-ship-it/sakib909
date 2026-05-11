import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _Step { email, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Step _step = _Step.email;
  final _emailCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpNodes = List.generate(6, (_) => FocusNode());
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final n in _otpNodes) n.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String get _otpCode => _otpCtrls.map((c) => c.text).join();

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red[600]),
      );

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) { _showError('Enter a valid email'); return; }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      setState(() { _step = _Step.otp; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Failed to send code. Please check the email.');
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) { _showError('Enter all 6 digits'); return; }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _emailCtrl.text.trim(),
        token: _otpCode,
        type: OtpType.recovery,
      );
      setState(() { _step = _Step.newPassword; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
      _showError('Invalid or expired code. Try again.');
      for (final c in _otpCtrls) c.clear();
      _otpNodes[0].requestFocus();
    }
  }

  Future<void> _updatePassword() async {
    final pass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;
    if (pass.length < 6) { _showError('Password must be at least 6 characters'); return; }
    if (pass != confirm) { _showError('Passwords do not match'); return; }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pass),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated! Please sign in.'), backgroundColor: Color(0xFF25D366)),
      );
      Navigator.of(context).pop();
    } catch (_) {
      setState(() => _loading = false);
      _showError('Failed to update password. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => _step == _Step.email
                    ? Navigator.pop(context)
                    : setState(() => _step = _Step.values[_step.index - 1]),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _step == _Step.email
                      ? 'Forgot Password'
                      : _step == _Step.otp
                          ? 'Verify Email'
                          : 'New Password',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  _step == _Step.email
                      ? 'Enter your registered email'
                      : _step == _Step.otp
                          ? 'Enter the 6-digit code'
                          : 'Choose a strong password',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 32),
          // Step indicator
          _stepBar(),
          const SizedBox(height: 32),
          // Content card
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: _step == _Step.email
                  ? _emailStep()
                  : _step == _Step.otp
                      ? _otpStep()
                      : _newPasswordStep(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stepBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(children: List.generate(3, (i) {
          final done = i < _step.index;
          final active = i == _step.index;
          return Expanded(
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: done || active ? Colors.white : Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF25D366))
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: active ? const Color(0xFF075E54) : Colors.white60,
                            fontWeight: FontWeight.bold, fontSize: 14,
                          ),
                        ),
                ),
              ),
              if (i < 2)
                Expanded(child: Container(
                  height: 2,
                  color: i < _step.index ? Colors.white : Colors.white24,
                )),
            ]),
          );
        })),
      );

  Widget _emailStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Reset via Email', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111B21))),
        const SizedBox(height: 6),
        const Text("We'll send a 6-digit code to your email address.", style: TextStyle(color: Color(0xFF8696A0), fontSize: 14, height: 1.5)),
        const SizedBox(height: 32),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.mail_outline_rounded, color: Color(0xFF54656F)),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendOtp,
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Send Code'),
          ),
        ),
      ]);

  Widget _otpStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Enter Verification Code', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111B21))),
        const SizedBox(height: 6),
        RichText(text: TextSpan(
          style: const TextStyle(color: Color(0xFF8696A0), fontSize: 14, height: 1.5),
          children: [
            const TextSpan(text: 'Code sent to '),
            TextSpan(text: _emailCtrl.text.trim(), style: const TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.w600)),
          ],
        )),
        const SizedBox(height: 36),
        // 6-digit OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _otpBox(i)),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_loading || _otpCode.length != 6) ? null : _verifyOtp,
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Verify Code'),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _loading ? null : _sendOtp,
            child: const Text("Didn't receive it? Resend", style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),
      ]);

  Widget _otpBox(int i) => SizedBox(
        width: 48,
        height: 58,
        child: TextFormField(
          controller: _otpCtrls[i],
          focusNode: _otpNodes[i],
          maxLength: 1,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111B21)),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF0F2F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF25D366), width: 2),
            ),
          ),
          onChanged: (v) {
            if (v.isNotEmpty) {
              if (i < 5) FocusScope.of(_otpNodes[i].context!).nextFocus();
            } else if (v.isEmpty && i > 0) {
              _otpNodes[i - 1].requestFocus();
            }
            setState(() {});
            if (_otpCode.length == 6) _verifyOtp();
          },
        ),
      );

  Widget _newPasswordStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Set New Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111B21))),
        const SizedBox(height: 6),
        const Text('Choose a strong password for your account.', style: TextStyle(color: Color(0xFF8696A0), fontSize: 14, height: 1.5)),
        const SizedBox(height: 32),
        TextField(
          controller: _newPassCtrl,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF54656F)),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF54656F)),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPassCtrl,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF54656F)),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF54656F)),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _updatePassword,
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Update Password'),
          ),
        ),
      ]);
}
