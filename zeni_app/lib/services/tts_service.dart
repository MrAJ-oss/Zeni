import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts tts = FlutterTts();

  TTSService() {
    tts.setLanguage("en-US");
    tts.setSpeechRate(0.47);
    tts.setVolume(1.0);
    tts.setPitch(1.0);
  }

  void speak(String text, {void Function()? onDone}) async {
    if (onDone != null) {
      tts.setCompletionHandler(() {
        onDone();
      });
    }
    await tts.speak(text);
  }

  Future<void> stop() async {
    await tts.stop();
  }
}