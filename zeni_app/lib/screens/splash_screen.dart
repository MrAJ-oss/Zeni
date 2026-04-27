// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await Future.delayed(const Duration(seconds: 2));

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
      body: Center(
        child: Text(
          "Zeni",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}