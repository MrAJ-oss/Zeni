// ignore_for_file: avoid_print

import 'package:speech_to_text/speech_to_text.dart';

class WakeWordService {
  final SpeechToText speech = SpeechToText();

  Function()? onWake;

  bool isListening = false;

  Future<void> init(Function() callback) async {
    onWake = callback;

    bool available = await speech.initialize();

    print("Speech available: $available");

    if (available) {
      start();
    }
  }

  void start() async {

    if (isListening) return;

    isListening = true;

    await speech.listen(
      listenFor: const Duration(days: 1),
      pauseFor: const Duration(days: 1),
      // ignore: deprecated_member_use
      partialResults: true,
      localeId: "en_US",

      onResult: (result) {

        String words =
        result.recognizedWords.toLowerCase();

        print("Heard: $words");

        if (words.contains("zeni")) {

          speech.stop();

          isListening = false;

          onWake?.call();
        }
      },
    );
  }

  void restart() {
    start();
  }
}