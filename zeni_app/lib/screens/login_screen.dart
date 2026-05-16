// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final passwordController = TextEditingController();
  bool loading = false;

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
      print("Device ID error: $e");
    }
    return "unknown_device";
  }

  Future<void> login() async {
    if (passwordController.text.trim().isEmpty) {
      showMessage("Enter password");
      return;
    }

    setState(() => loading = true);

    try {
      final deviceId = await getDeviceId();
      ApiService.setDeviceId(deviceId);

      final res = await ApiService.post("login", {
        "password": passwordController.text.trim(),
        "deviceId": deviceId,
      });

      if (res["success"] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("loggedIn", true);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        showMessage(res["message"] ?? "Login failed");
      }
    } catch (e) {
      print(e);
      showMessage("Server error. Check your connection.");
    }

    setState(() => loading = false);
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/zeni_logo.png", height: 120),
              const SizedBox(height: 30),
              const Text(
                "Zeni",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter Password",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Log In", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}