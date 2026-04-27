// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/approval_screen.dart';
import 'screens/setup_screen.dart';
import 'services/auth_service.dart';

class ZeniApp extends StatelessWidget {
  const ZeniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        "/home": (_) => const HomeScreen(),
        "/approval": (_) => const ApprovalScreen(),
        "/setup": (_) => SetupScreen(),
      },
      home: const EntryPoint(),
    );
  }
}

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  @override
  void initState() {
    super.initState();
    check();
  }

  void check() async {
    final approved = await AuthService.isApproved();
    final password = await AuthService.getPassword();

    if (!approved) {
      Navigator.pushReplacementNamed(context, "/approval");
    } else if (password == null) {
      Navigator.pushReplacementNamed(context, "/setup");
    } else {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}