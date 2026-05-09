import 'package:flutter/material.dart';

import '../services/voice_service.dart';
import '../services/tts_service.dart';
import '../services/api_service.dart';
import '../services/local_command_service.dart';
import '../services/wake_word_service.dart';
import '../services/tone_service.dart';
import '../services/voice_auth_service.dart';
import '../services/memory_service.dart';
import '../services/log_service.dart';

import '../widgets/zeni_bubble.dart';
import '../widgets/mic_button.dart';

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

  String statusText =
      "Say:\nHey Zeni\nYo Zeni\nHey Girl";

  @override
  void initState() {
    super.initState();

    initAll();
  }

  Future<void> initAll() async {

    await voice.init();

    await wake.init(() {
      startListening();
    });
  }

  void startListening() {

    setState(() {
      listening = true;

      statusText = "Listening...";
    });

    voice.startListening((text) async {

      setState(() {
        listening = false;
      });

      LogService.add(
        "User said: $text",
      );

      bool allowed =
      await VoiceAuthService.verify(text);

      if (!allowed) {

        await tts.speak(
          "Access denied",
        );

        LogService.add(
          "Unauthorized access attempt",
        );

        wake.restart();

        return;
      }

      String tone =
      ToneService.detectTone(text);

      String response;

      try {

        final res =
        await ApiService.post(
          "chat",
          {
            "message": text,
          },
        );

        response = res["reply"];

      } catch (e) {

        response =
            LocalCommandService.process(text);
      }

      response =
          ToneService.modifyResponse(
            response,
            tone,
          );

      MemoryService.add("User: $text");

      MemoryService.add(
        "Zeni: $response",
      );

      await tts.speak(response);

      LogService.add(
        "Zeni replied: $response",
      );

      setState(() {

        statusText =
        "Say:\nHey Zeni\nYo Zeni\nHey Girl";
      });

      wake.restart();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      body: Center(

        child: ZeniBubble(

          isListening: listening,

          onClose: () {},

          text: statusText,
        ),
      ),

      floatingActionButton: MicButton(
        onTap: startListening,
      ),
    );
  }
}