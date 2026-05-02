import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts tts = FlutterTts();

  Future speak(String text) async {
    await tts.stop();
    await tts.speak(text);
  }
}