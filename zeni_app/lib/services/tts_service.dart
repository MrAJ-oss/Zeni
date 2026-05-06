import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts tts = FlutterTts();

  TTSService() {
    tts.setLanguage("en-US");
    tts.setSpeechRate(0.5);
  }

  void speak(String text) {
    tts.speak(text);
  }
}