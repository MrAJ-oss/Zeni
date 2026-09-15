import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class DevicesScreen extends StatefulWidget {
  final String deviceId;
  const DevicesScreen({super.key, required this.deviceId});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<dynamic> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await http.get(
      Uri.parse('${ZeniConfig.apiBaseUrl}/devices'),
      headers: {'x-device-id': widget.deviceId},
    );
    final body = jsonDecode(res.body);
    setState(() {
      _devices = body['devices'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, i) {
                final d = _devices[i];
                return ListTile(
                  title: Text(d['name'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${d['device_type']} - ${d['status']}', style: const TextStyle(color: Colors.white38)),
                );
              },
            ),
    );
  }
}
