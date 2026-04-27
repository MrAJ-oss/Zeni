import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class ApiService {
  static Future<Map<String, dynamic>> post(String endpoint, Map body) async {
    final res = await http.post(
      Uri.parse("${Config.baseUrl}/$endpoint"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return jsonDecode(res.body);
  }
}