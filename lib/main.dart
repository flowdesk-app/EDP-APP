import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const FlowDeskApp());
}

class FlowDeskApp extends StatelessWidget {
  const FlowDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDP APP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF29B6F6)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}