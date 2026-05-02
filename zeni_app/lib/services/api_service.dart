import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String base = "https://zeni-1.onrender.com";

  static Future<Map<String, dynamic>> post(
      String endpoint, Map body) async {
    final res = await http.post(
      Uri.parse("$base/$endpoint"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final res = await http.get(Uri.parse("$base/$endpoint"));
    return jsonDecode(res.body);
  }
}