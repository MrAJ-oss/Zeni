// ignore_for_file: avoid_print

import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {

  final SpeechToText speech =
  SpeechToText();

  Future<void> init() async {

    bool available =
    await speech.initialize();

    print("Speech available: $available");
  }

  void startListening(
      Function(String) onResult,
      ) async {

    await speech.listen(

      localeId: "en_US",

      // ignore: deprecated_member_use
      listenMode: ListenMode.confirmation,

      onResult: (result) {

        if (result.finalResult) {

          String text =
          result.recognizedWords;

          print("Final speech: $text");

          speech.stop();

          onResult(text);
        }
      },
    );
  }

  void stop() {

    speech.stop();
  }
}