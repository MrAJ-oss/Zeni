import 'dart:convert';
import 'package:http/http.dart' as http;

class ZeniBrain {
  // 🔥 CHANGE THIS TO YOUR PC IP
  static const String baseUrl = "http://10.241.123.58";

  static Future<String> sendMessage(String text) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/voice"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"] ?? "No reply from Zeni";
      } else {
        return "Server error ${response.statusCode}";
      }
    } catch (e) {
      return "Connection failed (check WiFi/IP)";
    }
  }
}