import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';
import 'home_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});
  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _userNameController = TextEditingController();
  final _deviceNameController = TextEditingController(text: 'My Device');
  final _passwordController = TextEditingController();
  String? _pendingDeviceId;
  String? _error;
  bool _busy = false;

  Future<void> _register() async {
    if (_userNameController.text.trim().isEmpty) return;
    setState(() { _busy = true; _error = null; });

    try {
      final userRes = await http.post(
        Uri.parse('${ZeniConfig.apiBaseUrl}/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': _userNameController.text.trim()}),
      );
      final userBody = jsonDecode(userRes.body);
      if (userBody['ok'] != true) throw Exception('user creation failed');
      final userId = userBody['id'];

      final devRes = await http.post(
        Uri.parse('${ZeniConfig.apiBaseUrl}/devices/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'name': _deviceNameController.text.trim(), 'deviceType': 'mobile'}),
      );
      final devBody = jsonDecode(devRes.body);
      if (devBody['ok'] != true) throw Exception('device registration failed');

      setState(() {
        _pendingDeviceId = devBody['deviceId'];
        _busy = false;
      });
    } catch (e) {
      setState(() { _busy = false; _error = 'Could not reach the server. Check the API URL and that it is running.'; });
    }
  }

  Future<void> _approve() async {
    if (_pendingDeviceId == null || _passwordController.text.isEmpty) return;
    setState(() { _busy = true; _error = null; });

    try {
      final res = await http.post(
        Uri.parse('${ZeniConfig.apiBaseUrl}/devices/$_pendingDeviceId/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': _passwordController.text}),
      );
      final body = jsonDecode(res.body);
      if (body['ok'] != true) {
        setState(() { _busy = false; _error = 'Wrong password.'; });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_id', _pendingDeviceId!);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(deviceId: _pendingDeviceId!)),
        );
      }
    } catch (e) {
      setState(() { _busy = false; _error = 'Approval failed.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Set up Zeni', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              if (_pendingDeviceId == null) ...[
                TextField(
                  controller: _userNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Your name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _deviceNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Device name'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _busy ? null : _register, child: const Text('Register')),
              ] else ...[
                Text('Device registered. Enter your MAIN_PASSWORD to approve this device.',
                    style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _busy ? null : _approve, child: const Text('Approve this device')),
              ],
              if (_error != null) Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
