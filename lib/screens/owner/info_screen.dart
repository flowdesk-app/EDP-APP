import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Info', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Color(0xFF5F6368)),
            const SizedBox(height: 16),
            const Text(
              'Information Section',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your company info or settings here.',
              style: TextStyle(color: Color(0xFF5F6368)),
            ),
          ],
        ),
      ),
    );
  }
}
