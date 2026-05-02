import 'api_service.dart';

class AuthService {
  static Future<String> login(String password, String deviceId) async {
    final res = await ApiService.post("login", {
      "password": password,
      "deviceId": deviceId
    });

    return res["status"];
  }

  static Future setup(
      String name, String password, String deviceId) async {
    return await ApiService.post("setup", {
      "name": name,
      "password": password,
      "deviceId": deviceId
    });
  }
}