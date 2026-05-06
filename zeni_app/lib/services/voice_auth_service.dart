import 'package:http/http.dart' as http;

class VoiceAuthService {
  static Future<bool> verify() async {
    try {
      final res = await http.get(
        Uri.parse("http://10.241.123.58:5000/verify"),
      );

      return res.body.contains("allowed");
    } catch (e) {
      return true;
    }
  }
}