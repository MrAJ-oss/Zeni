import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class MemoryScreen extends StatefulWidget {
  final String deviceId;
  const MemoryScreen({super.key, required this.deviceId});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  List<dynamic> _memories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await http.get(
      Uri.parse('${ZeniConfig.apiBaseUrl}/memory'),
      headers: {'x-device-id': widget.deviceId},
    );
    final body = jsonDecode(res.body);
    setState(() {
      _memories = body['memories'] ?? [];
      _loading = false;
    });
  }

  Future<void> _delete(String id) async {
    await http.delete(
      Uri.parse('${ZeniConfig.apiBaseUrl}/memory/$id'),
      headers: {'x-device-id': widget.deviceId},
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _memories.length,
              itemBuilder: (context, i) {
                final m = _memories[i];
                return ListTile(
                  title: Text(m['content'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text(m['category'], style: const TextStyle(color: Colors.white38)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () => _delete(m['id']),
                  ),
                );
              },
            ),
    );
  }
}
