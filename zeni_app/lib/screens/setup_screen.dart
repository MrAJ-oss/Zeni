import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SetupScreen extends StatelessWidget {
  final TextEditingController controller = TextEditingController();

  SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Set Password"),
          TextField(controller: controller),
          ElevatedButton(
            onPressed: () async {
              await AuthService.setPassword(controller.text);
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, "/home");
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}