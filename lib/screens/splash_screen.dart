import 'package:flutter/material.dart';
import '../widgets/flowdesk_logo.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate database activation and background loading logic
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlowdeskLogo(fontSize: 56),
            const SizedBox(height: 16),
            const Text(
              'Supply Chain Management',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF5F6368),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF29B6F6)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Activating database connections...',
              style: TextStyle(
                color: Color(0xFF5F6368),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
