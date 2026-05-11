import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'create_profile_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _nodes[0].requestFocus());
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length != 6) return;
    final prov = context.read<AuthProvider>();
    final ok = await prov.verifyOtp(widget.email, _code);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CreateProfileScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(prov.errorMessage ?? 'Invalid code'),
          backgroundColor: Colors.red[600]));
      prov.clearError();
      for (final c in _ctrls) c.clear();
      _nodes[0].requestFocus();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final filled = _code.length;

    return Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Verify Email',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Enter the 6-digit verification code',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 32),
          // Email badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.mail_outline_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(widget.email,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
          const SizedBox(height: 32),
          // Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Enter Verification Code',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111B21))),
                const SizedBox(height: 6),
                const Text('Check your inbox or spam folder for the code.',
                    style: TextStyle(color: Color(0xFF8696A0), fontSize: 13, height: 1.5)),
                const SizedBox(height: 36),

                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _box(i, filled)),
                ),

                const SizedBox(height: 36),
                // Progress indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: filled / 6,
                    backgroundColor: const Color(0xFFF0F2F5),
                    color: const Color(0xFF25D366),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 8),
                Text('$filled / 6 digits entered',
                    style: const TextStyle(color: Color(0xFF8696A0), fontSize: 12)),

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (auth.isLoading || filled != 6) ? null : _verify,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Verify & Continue'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Didn't get it? Go back & resend",
                        style: TextStyle(
                            color: Color(0xFF25D366),
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _box(int i, int filled) {
    final isFilled = _ctrls[i].text.isNotEmpty;
    return SizedBox(
      width: 48,
      height: 60,
      child: TextField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111B21)),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isFilled
              ? const Color(0xFFE7F8EE)
              : const Color(0xFFF0F2F5),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isFilled ? const Color(0xFF25D366) : Colors.grey.shade200,
                width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF25D366), width: 2.5),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && i < 5) {
            _nodes[i + 1].requestFocus();
          } else if (v.isEmpty && i > 0) {
            _nodes[i - 1].requestFocus();
          }
          setState(() {});
          if (_code.length == 6) _verify();
        },
      ),
    );
  }
}
