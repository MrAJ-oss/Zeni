// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ZeniHome());
  }
}

class ZeniHome extends StatefulWidget {
  const ZeniHome({super.key});

  @override
  State<ZeniHome> createState() => _ZeniHomeState();
}

class _ZeniHomeState extends State<ZeniHome> {
  final speech = SpeechToText();
  final tts = FlutterTts();

  String text = "Say 'Zeni' to start...";
  final apiUrl = "https://zeni-1.onrender.com/api/voice";

  @override
  void initState() {
    super.initState();

    tts.setLanguage("en-US");
    tts.setSpeechRate(0.45);
    tts.setPitch(1.1);

    startListening();
  }

  void startListening() async {
    bool available = await speech.initialize();

    if (available) {
      speech.listen(
        listenMode: ListenMode.dictation,
        partialResults: true,
        onResult: (result) {
          text = result.recognizedWords;

          if (text.toLowerCase().contains("zeni")) {
            final command = text
                .toLowerCase()
                .replaceFirst("zeni", "")
                .trim();

            handle(command);
          }

          setState(() {});
        },
      );
    }
  }

  void handle(String input) async {
    final res = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": input}),
    );

    final data = jsonDecode(res.body);
    speak(data["reply"]);
  }

  void speak(String msg) async {
    await tts.speak(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}