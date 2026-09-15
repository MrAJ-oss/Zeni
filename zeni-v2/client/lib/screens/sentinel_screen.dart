import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class SentinelScreen extends StatefulWidget {
  final String deviceId;
  const SentinelScreen({super.key, required this.deviceId});

  @override
  State<SentinelScreen> createState() => _SentinelScreenState();
}

class _SentinelScreenState extends State<SentinelScreen> {
  final _ipController = TextEditingController();
  final _linkController = TextEditingController();
  String? _ipResult;
  String? _linkResult;
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final res = await http.get(
      Uri.parse('${ZeniConfig.apiBaseUrl}/sentinel/events'),
      headers: {'x-device-id': widget.deviceId},
    );
    final body = jsonDecode(res.body);
    setState(() => _events = body['events'] ?? []);
  }

  Future<void> _lookupIp() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;
    final res = await http.get(
      Uri.parse('${ZeniConfig.apiBaseUrl}/sentinel/ip-lookup/$ip'),
      headers: {'x-device-id': widget.deviceId},
    );
    final body = jsonDecode(res.body);
    setState(() => _ipResult = body['ok'] == true ? '${body['country']} - ${body['org']}' : 'Lookup failed');
    _loadEvents();
  }

  Future<void> _scanLink() async {
    final url = _linkController.text.trim();
    if (url.isEmpty) return;
    final res = await http.post(
      Uri.parse('${ZeniConfig.apiBaseUrl}/sentinel/scan-link'),
      headers: {'Content-Type': 'application/json', 'x-device-id': widget.deviceId},
      body: jsonEncode({'url': url}),
    );
    final body = jsonDecode(res.body);
    setState(() => _linkResult = body['status'] == 'NOT_IMPLEMENTED'
        ? 'Link scanning needs a threat-intel provider configured on the server.'
        : jsonEncode(body));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sentinel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('IP lookup', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          Row(children: [
            Expanded(child: TextField(controller: _ipController, style: const TextStyle(color: Colors.white))),
            IconButton(icon: const Icon(Icons.search), onPressed: _lookupIp),
          ]),
          if (_ipResult != null) Text(_ipResult!, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          const Text('Link scan', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          Row(children: [
            Expanded(child: TextField(controller: _linkController, style: const TextStyle(color: Colors.white))),
            IconButton(icon: const Icon(Icons.shield_outlined), onPressed: _scanLink),
          ]),
          if (_linkResult != null) Text(_linkResult!, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          const Text('Recent events', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ..._events.map((e) => ListTile(
                dense: true,
                title: Text(e['event_type'], style: const TextStyle(color: Colors.white)),
                subtitle: Text(e['created_at'], style: const TextStyle(color: Colors.white38)),
              )),
        ],
      ),
    );
  }
}
