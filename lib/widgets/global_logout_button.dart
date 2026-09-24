import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';

class GlobalLogoutButton extends StatelessWidget {
  const GlobalLogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout, color: Colors.redAccent),
      tooltip: 'Logout',
      onPressed: () async {
        await ApiService().logout();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
    );
  }
}
