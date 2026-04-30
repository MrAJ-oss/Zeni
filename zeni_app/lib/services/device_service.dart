import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static String? deviceId;

  static Future<void> init(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();

    deviceId = prefs.getString("deviceId");

    if (deviceId == null) {
      final info = await DeviceInfoPlugin().androidInfo;
      deviceId = info.id;

      await prefs.setString("deviceId", deviceId!);

      await http.post(
        Uri.parse("$baseUrl/api/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": deviceId,
          "name": "My Phone"
        }),
      );
    }
  }
}