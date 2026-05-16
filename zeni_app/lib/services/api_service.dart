import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = "https://zeni-1.onrender.com";
  static const timeout = Duration(seconds: 15);

  static String _deviceId = "unknown_device";

  static void setDeviceId(String id) {
    _deviceId = id;
  }

  static String get deviceId => _deviceId;

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map body,
  ) async {
    final res = await http
        .post(
          Uri.parse("$baseUrl/$endpoint"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final res = await http
        .get(
          Uri.parse("$baseUrl/$endpoint"),
          headers: {"Content-Type": "application/json"},
        )
        .timeout(timeout);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final res = await http
        .delete(
          Uri.parse("$baseUrl/$endpoint"),
          headers: {"Content-Type": "application/json"},
        )
        .timeout(timeout);
    return jsonDecode(res.body);
  }
}