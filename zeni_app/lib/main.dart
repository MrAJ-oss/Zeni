import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ZeniApp());
}

class ZeniApp extends StatelessWidget {
  const ZeniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zeni',
      theme: ThemeData.dark(),
      home: const CheckLoginScreen(),
    );
  }
}

class CheckLoginScreen extends StatefulWidget {
  const CheckLoginScreen({super.key});

  @override
  State<CheckLoginScreen> createState() => _CheckLoginScreenState();
}

class _CheckLoginScreenState extends State<CheckLoginScreen> {

  bool loading = true;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();

    bool savedLogin = prefs.getBool("loggedIn") ?? false;

    setState(() {
      loggedIn = savedLogin;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return loggedIn
        ? const HomeScreen()
        : const LoginScreen();
  }
}