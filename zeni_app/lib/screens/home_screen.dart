import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    login();
  }

  Future<void> login() async {
    await ApiService.post("login", {
      "password": "anuj@zeni123",
      "deviceId": "mobile_001"
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Zeni is Ready"),
      ),
    );
  }
}