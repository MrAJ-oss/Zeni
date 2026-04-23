import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ZeniBrain {
  Future<void> sendCommand(String text) async {
    final prefs = await SharedPreferences.getInstance();
    String deviceId = prefs.getString("deviceId") ?? "";

    await http.post(
      Uri.parse("http://10.241.123.58:3000/api/voice"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "text": text,
        "deviceId": deviceId,
        "isVerified": true
      }),
    );
  }
}