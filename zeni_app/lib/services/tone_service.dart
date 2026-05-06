import 'package:http/http.dart' as http;

class ToneService {
  static String detectTone(String text) {
    text = text.toLowerCase();

    if (text.contains("sad") || text.contains("bad")) return "sad";
    if (text.contains("angry") || text.contains("hate")) return "angry";
    if (text.contains("happy") || text.contains("great")) return "happy";

    return "neutral";
  }

  static Future<String> getVoiceEmotion() async {
    try {
      final res = await http.get(
        Uri.parse("http://YOUR_PC_IP:5001/emotion"),
      );

      return res.body;
    } catch (e) {
      return "neutral";
    }
  }

  static String mergeTone(String textTone, String voiceTone) {
    if (voiceTone != "neutral") return voiceTone;
    return textTone;
  }

  static String modifyResponse(String response, String tone) {
    switch (tone) {
      case "sad":
        return "Hey… I’m here for you. $response";
      case "angry":
        return "Calm down, I got you. $response";
      case "happy":
        return "That’s awesome 😄 $response";
      default:
        return response;
    }
  }
}