import 'package:shared_preferences/shared_preferences.dart';

class VoiceBiometrics {
  Future<void> saveSample(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("voice_sample", text);
  }

  Future<String?> getSample() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("voice_sample");
  }

  Future<bool> verify(String spokenText) async {
    final sample = await getSample();

    if (sample == null) return true;

    spokenText = spokenText.toLowerCase();
    sample.toLowerCase();

    return spokenText.contains(sample);
  }
}