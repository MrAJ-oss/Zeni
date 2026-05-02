import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final name = TextEditingController();
  final pass = TextEditingController();

  void setup() async {
    await AuthService.setup(
      name.text,
      pass.text,
      "mobile_001",
    );

    // ignore: use_build_context_synchronously
    Navigator.pushReplacementNamed(context, "/");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: name, decoration: const InputDecoration(hintText: "Name")),
            TextField(controller: pass, decoration: const InputDecoration(hintText: "Password")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: setup, child: const Text("Setup Zeni"))
          ],
        ),
      ),
    );
  }
}