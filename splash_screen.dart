import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.4, 1.0));
    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final prov = context.read<AuthProvider>();
    await prov.checkAuthStatus();
    if (!mounted) return;
    if (prov.isAuthenticated) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF075E54),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: const Icon(Icons.chat_rounded,
                    size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _fade,
              child: const Column(children: [
                Text('ChatApp',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1)),
                SizedBox(height: 6),
                Text('Connect. Chat. Call.',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        letterSpacing: 0.3)),
              ]),
            ),
            const SizedBox(height: 80),
            const CircularProgressIndicator(
                color: Colors.white54, strokeWidth: 2),
          ]),
        ),
      );
}
