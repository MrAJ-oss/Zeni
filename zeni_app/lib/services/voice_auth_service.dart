import 'package:shared_preferences/shared_preferences.dart';

class VoiceAuthService {
  static const keyPhrase = "voice_phrase";

  static Future<void> savePhrase(String phrase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyPhrase, phrase.toLowerCase());
  }

  static Future<bool> verify(String input) async {
    final prefs = await SharedPreferences.getInstance();
    final phrase = prefs.getString(keyPhrase);

    if (phrase == null) return true;

    return input.toLowerCase().contains(phrase);
  }
}