import 'package:flutter/material.dart';
import 'screens/main_responsive_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verivio - Lapisan Verifikasi AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070514),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF8B5CF6),
          surface: const Color(0xFF131127),
          background: const Color(0xFF070514),
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const MainResponsiveScreen(),
    );
  }
}
