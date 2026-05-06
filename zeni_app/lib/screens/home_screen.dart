import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/tts_service.dart';
import '../services/api_service.dart';
import '../services/wake_word_service.dart';
import '../services/tone_service.dart';
import '../services/voice_auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final voice = VoiceService();
  final tts = TTSService();
  final wake = WakeWordService();

  bool listening = false;

  @override
  void initState() {
    super.initState();

    voice.init();

    wake.init(() {
      startListening();
    });
  }

  void startListening() {
    setState(() => listening = true);

    voice.startListening((text) async {
      setState(() => listening = false);

      // 🔐 Voice Auth
      bool allowed = await VoiceAuthService.verify();

      if (!allowed) {
        tts.speak("Access denied");
        wake.restart();
        return;
      }

      // 🎭 TEXT TONE
      String tone = ToneService.detectTone(text);

      // 🎤 VOICE EMOTION (from backend)
      String voiceEmotion = await ToneService.getVoiceEmotion();

      String finalTone = ToneService.mergeTone(tone, voiceEmotion);

      String response;

      try {
        final res = await ApiService.post("chat", {
          "message": text
        });

        response = res["reply"];
      } catch (e) {
        response = "Something went wrong";
      }

      response = ToneService.modifyResponse(response, finalTone);

      tts.speak(response);

      Future.delayed(const Duration(seconds: 1), () {
        wake.restart();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          listening ? "Listening..." : "Say 'Zeni'",
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}