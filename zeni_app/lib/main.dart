import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/approval_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZeniApp());
}

class ZeniApp extends StatelessWidget {
  const ZeniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Zeni",

      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),

      // 🔥 Routes
      routes: {
        "/home": (_) => const HomeScreen(),
        "/approval": (_) => const ApprovalScreen(),
        "/setup": (_) => SetupScreen(),
      },

      // 🔥 Start from splash (important)
      home: const SplashScreen(),
    );
  }
}