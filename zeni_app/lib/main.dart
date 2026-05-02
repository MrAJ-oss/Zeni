import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';

void main() {
  runApp(const ZeniApp());
}

class ZeniApp extends StatelessWidget {
  const ZeniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Entry(),
    );
  }
}

// ===== ENTRY =====

class Entry extends StatefulWidget {
  const Entry({super.key});

  @override
  State<Entry> createState() => _EntryState();
}

class _EntryState extends State<Entry> {
  final base = "https://zeni-1.onrender.com";

  bool loading = true;
  bool hasUser = false;

  @override
  void initState() {
    super.initState();
    check();
  }

  Future<void> check() async {
    try {
      final res = await http.get(Uri.parse("$base/status"));
      final data = jsonDecode(res.body);

      setState(() {
        hasUser = data["hasUser"];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: Text("Starting Zeni...")),
      );
    }

    return hasUser ? const HomeScreen() : SetupScreen();
  }
}