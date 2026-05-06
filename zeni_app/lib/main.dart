import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ZeniApp());
}

class ZeniApp extends StatelessWidget {
  const ZeniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}