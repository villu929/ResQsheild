import 'package:flutter/material.dart';
import 'screens/getstarted_screen.dart';

void main() {
  runApp(const ResQShieldApp());
}

class ResQShieldApp extends StatelessWidget {
  const ResQShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ResQShield - Flood & Disaster Protection',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFF063A5B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0877C9),
        ),
      ),
      home: const GetStartedScreen(),
    );
  }
}
