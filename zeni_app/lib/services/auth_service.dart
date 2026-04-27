import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static Future<bool> isApproved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("approved") ?? false;
  }

  static Future<void> setApproved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("approved", true);
  }

  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("password");
  }

  static Future<void> setPassword(String pass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("password", pass);
  }

  static Future<Map> registerDevice(String deviceId) async {
    return await ApiService.post("register-device", {
      "deviceId": deviceId
    });
  }
}