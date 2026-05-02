import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const ZeniApp());
}

class ZeniApp extends StatelessWidget {
  const ZeniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String baseUrl = "https://zeni-1.onrender.com";

  late stt.SpeechToText speech;
  late FlutterTts tts;

  bool isListening = false;
  String text = "Tap mic and speak";
  String reply = "";

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    tts = FlutterTts();
  }

  Future<void> startListening() async {
    bool available = await speech.initialize();

    if (available) {
      setState(() => isListening = true);

      speech.listen(onResult: (result) {
        setState(() {
          text = result.recognizedWords;
        });

        if (result.finalResult) {
          sendCommand(text);
        }
      });
    } else {
      setState(() => text = "Mic not available");
    }
  }

  Future<void> stopListening() async {
    await speech.stop();
    setState(() => isListening = false);
  }

  Future<void> sendCommand(String text) async {
    setState(() {
      reply = "Thinking...";
    });

    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/voice"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "text": text,
              "deviceId": "mobile123"
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);

      setState(() {
        reply = data["reply"] ?? "No response";
      });

      await tts.speak(reply);

    } catch (e) {
      setState(() {
        reply = "❌ Server error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Zeni"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 20),

            Text(
              reply,
              style: const TextStyle(color: Colors.green),
            ),

            const SizedBox(height: 40),

            FloatingActionButton(
              onPressed: isListening ? stopListening : startListening,
              child: Icon(isListening ? Icons.mic : Icons.mic_none),
            ),
          ],
        ),
      ),
    );
  }
}