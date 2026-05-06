import 'package:speech_to_text/speech_to_text.dart';

class WakeWordService {
  final SpeechToText speech = SpeechToText();

  Function()? onWake;

  Future<void> init(Function() callback) async {
    onWake = callback;
    await speech.initialize();
    start();
  }

  void start() {
    speech.listen(
      onResult: (result) {
        String words = result.recognizedWords.toLowerCase();

        if (words.contains("zeni")) {
          speech.stop();
          onWake?.call();
        }
      },
    );
  }

  void restart() {
    start();
  }
}