// ignore_for_file: avoid_print

import 'package:speech_to_text/speech_to_text.dart';

class WakeWordService {

  final SpeechToText speech = SpeechToText();

  Function()? onWake;

  bool initialized = false;
  bool listening = false;

  final List<String> wakePhrases = [

    "hey zeni",
    "yo zeni",
    "i need you zeni",
    "hey girl",
    "let's do it",
    "lets do it",
    "wake up zeni",
    "zeni listen",
    "come on zeni",
  ];

  Future<void> init(Function() callback) async {

    onWake = callback;

    initialized = await speech.initialize(

      onStatus: (status) {

        print("Speech status: $status");

        if (status == "done") {
          restart();
        }
      },

      onError: (error) {

        print("Speech error: $error");

        restart();
      },
    );

    print("Speech initialized: $initialized");

    if (initialized) {
      start();
    }
  }

  void start() async {

    if (!initialized) return;

    if (listening) return;

    listening = true;

    await speech.listen(

      listenFor: const Duration(days: 1),

      pauseFor: const Duration(days: 1),

      // ignore: deprecated_member_use
      partialResults: true,

      localeId: "en_US",

      onResult: (result) {

        final words =
        result.recognizedWords.toLowerCase();

        print("Heard: $words");

        for (String trigger in wakePhrases) {

          if (words.contains(trigger)) {

            print("Wake phrase detected: $trigger");

            speech.stop();

            listening = false;

            onWake?.call();

            break;
          }
        }
      },
    );
  }

  void restart() {

    if (!initialized) return;

    if (listening) return;

    Future.delayed(
      const Duration(seconds: 1),
          () {
        start();
      },
    );
  }

  void stop() {

    speech.stop();

    listening = false;
  }
}