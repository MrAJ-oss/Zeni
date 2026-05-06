import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController controller = TextEditingController();

  String status = "";
  bool loading = false;

  void login() async {
    setState(() {
      loading = true;
      status = "";
    });

    try {
      final res = await ApiService.post("login", {
        "password": controller.text,
        "deviceId": "mobile_001"
      });

      if (res["status"] == "ok") {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (res["status"] == "pending") {
        setState(() {
          status = "Waiting for approval...";
          loading = false;
        });
      } else {
        setState(() {
          status = "Wrong password";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = "Server error";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Zeni Login",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Enter Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : login,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Login"),
            ),

            const SizedBox(height: 15),

            Text(
              status,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}