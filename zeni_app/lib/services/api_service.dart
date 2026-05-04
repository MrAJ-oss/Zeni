import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String base = "http://10.0.2.2:3000";

  static Future<Map<String, dynamic>> post(String path, Map body) async {
    final res = await http.post(
      Uri.parse("$base/$path"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return jsonDecode(res.body);
  }
}