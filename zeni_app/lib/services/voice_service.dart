import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> init() async {
    return await _speech.initialize();
  }

  void startListening(Function(String) onResult) {
    _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  void stop() {
    _speech.stop();
  }
}