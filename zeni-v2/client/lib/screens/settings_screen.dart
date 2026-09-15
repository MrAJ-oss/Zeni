import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/geofence_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _wakeWordEnabled = false;
  bool _geofenceEnabled = false;
  bool _homeLocationSet = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wakeWordEnabled = prefs.getBool('wake_word_enabled') ?? false;
      _geofenceEnabled = prefs.getBool('geofence_enabled') ?? false;
      _homeLocationSet = prefs.getDouble('home_lat') != null;
    });
  }

  Future<void> _toggleWakeWord(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wake_word_enabled', value);
    setState(() => _wakeWordEnabled = value);
  }

  Future<void> _toggleGeofence(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('geofence_enabled', value);
    setState(() => _geofenceEnabled = value);
  }

  Future<void> _setHomeLocation() async {
    setState(() => _busy = true);
    try {
      await GeofenceService.setHomeToCurrentLocation();
      setState(() { _homeLocationSet = true; _busy = false; });
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location — check location permission.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Wake word ("Zeni")', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Foreground only — listens continuously while the app is open. Uses more battery.',
              style: TextStyle(color: Colors.white38),
            ),
            value: _wakeWordEnabled,
            onChanged: _toggleWakeWord,
          ),
          const Divider(color: Colors.white12),
          ListTile(
            title: const Text('Home location', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              _homeLocationSet ? 'Set' : 'Not set',
              style: const TextStyle(color: Colors.white38),
            ),
            trailing: TextButton(
              onPressed: _busy ? null : _setHomeLocation,
              child: const Text('Use current location'),
            ),
          ),
          SwitchListTile(
            title: const Text('Greet me when I get home', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Requires location permission and the app running. Cooldown of 20 minutes between check-ins.',
              style: TextStyle(color: Colors.white38),
            ),
            value: _geofenceEnabled,
            onChanged: _homeLocationSet ? _toggleGeofence : null,
          ),
        ],
      ),
    );
  }
}
