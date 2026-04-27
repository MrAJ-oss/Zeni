// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ApprovalScreen extends StatelessWidget {
  const ApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text("Simulate Approval"),
          onPressed: () async {
            await AuthService.setApproved();
            Navigator.pushReplacementNamed(context, "/home");
          },
        ),
      ),
    );
  }
}