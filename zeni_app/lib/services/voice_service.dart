// ignore_for_file: avoid_print

import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText speech = SpeechToText();
  bool _initialized = false;

  Future<void> init() async {
    _initialized = await speech.initialize(
      onError: (error) => print("Speech error: $error"),
      onStatus: (status) => print("Speech status: $status"),
    );
    print("Speech available: $_initialized");
  }

  bool get isAvailable => _initialized;

  void startListening(
    Function(String) onResult, {
    Function()? onOffline,
  }) async {
    if (!_initialized) {
      onOffline?.call();
      return;
    }

    if (speech.isListening) {
      await speech.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    bool gotResult = false;

    await speech.listen(
      localeId: "en_US",
      // ignore: deprecated_member_use
      listenMode: ListenMode.confirmation,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords.trim();
          speech.stop();
          if (text.isEmpty) {
            onOffline?.call();
          } else {
            gotResult = true;
            onResult(text);
          }
        }
      },
    );

    await Future.delayed(const Duration(seconds: 11));
    if (!gotResult && !speech.isListening) {
      onOffline?.call();
    }
  }

  void stop() {
    speech.stop();
  }
}