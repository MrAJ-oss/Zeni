import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class ProjectsScreen extends StatefulWidget {
  final String deviceId;
  const ProjectsScreen({super.key, required this.deviceId});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<dynamic> _projects = [];
  bool _loading = true;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await http.get(
      Uri.parse('${ZeniConfig.apiBaseUrl}/projects'),
      headers: {'x-device-id': widget.deviceId},
    );
    final body = jsonDecode(res.body);
    setState(() {
      _projects = body['projects'] ?? [];
      _loading = false;
    });
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) return;
    await http.post(
      Uri.parse('${ZeniConfig.apiBaseUrl}/projects'),
      headers: {'Content-Type': 'application/json', 'x-device-id': widget.deviceId},
      body: jsonEncode({'name': _nameController.text.trim()}),
    );
    _nameController.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'New project name'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _create),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _projects.length,
                    itemBuilder: (context, i) {
                      final p = _projects[i];
                      return ListTile(
                        title: Text(p['name'], style: const TextStyle(color: Colors.white)),
                        subtitle: Text(p['status'], style: const TextStyle(color: Colors.white38)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
