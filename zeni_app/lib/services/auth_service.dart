import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> setup(String name, String password) async {
    return await ApiService.post("setup", {
      "name": name,
      "password": password,
    });
  }
}