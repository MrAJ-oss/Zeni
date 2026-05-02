import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();

  Future init() async {
    await _speech.initialize();
  }

  void start(Function(String) onResult) {
    _speech.listen(onResult: (res) {
      if (res.finalResult) {
        onResult(res.recognizedWords);
      }
    });
  }
}