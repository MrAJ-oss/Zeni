import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = "https://zeni-1.onrender.com";

  static Future<Map<String, dynamic>> post(
      String endpoint, Map body) async {
    final res = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return jsonDecode(res.body);
  }
}