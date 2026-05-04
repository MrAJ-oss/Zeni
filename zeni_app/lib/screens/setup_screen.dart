import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final name = TextEditingController();
  final pass = TextEditingController();

  bool loading = false;
  String error = "";

  Future<void> setup() async {
    if (name.text.isEmpty || pass.text.isEmpty) {
      setState(() => error = "Enter all fields");
      return;
    }

    setState(() {
      loading = true;
      error = "";
    });

    try {
      final res = await AuthService.setup(
        name.text.trim(),
        pass.text.trim(),
      );

      if (res["status"] == "created") {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() => error = "User already exists");
      }

    } catch (e) {
      setState(() => error = "Server error");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text("Welcome to Zeni", style: TextStyle(fontSize: 22)),

            const SizedBox(height: 20),

            TextField(
              controller: name,
              decoration: const InputDecoration(hintText: "Name"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Password"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : setup,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Setup Zeni"),
            ),

            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}