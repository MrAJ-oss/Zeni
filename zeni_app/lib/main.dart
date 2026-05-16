import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';

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

  Future<String> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return info.id;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.identifierForVendor ?? "unknown_ios";
      }
    } catch (e) {
      // ignore
    }
    return "unknown_device";
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLogin = prefs.getBool("loggedIn") ?? false;

    if (savedLogin) {
      final deviceId = await getDeviceId();
      ApiService.setDeviceId(deviceId);
    }

    setState(() {
      loggedIn = savedLogin;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return loggedIn ? const HomeScreen() : const LoginScreen();
  }
}