// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../services/voice_service.dart';
import '../services/tts_service.dart';
import '../services/api_service.dart';
import '../services/local_command_service.dart';
import '../services/tone_service.dart';
import '../services/memory_service.dart';
import '../services/log_service.dart';

import '../widgets/zeni_bubble.dart';
import '../widgets/chat_message.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final voice = VoiceService();
  final tts = TTSService();
  final ScrollController _scrollController = ScrollController();

  bool listening = false;
  bool thinking = false;
  bool isOnline = true;
  String statusText = "Tap mic to talk to Zeni";

  @override
  void initState() {
    super.initState();
    initAll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> initAll() async {
    await voice.init();
    await checkConnectivity();
    await loadHistoryFromServer();
  }

  Future<void> loadHistoryFromServer() async {
    try {
      final res = await ApiService.get("history/${ApiService.deviceId}");
      final history = res["history"] as List? ?? [];
      MemoryService.setMessages(
        history.map((m) => Map<String, String>.from(m)).toList(),
      );
      if (mounted) setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    } catch (e) {
      print("Load history error: $e");
    }
  }

  Future<void> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      // ignore: unrelated_type_equality_checks
      setState(() => isOnline = result != ConnectivityResult.none);
    }

    Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        // ignore: unrelated_type_equality_checks
        setState(() => isOnline = result != ConnectivityResult.none);
      }
    });
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void startListening() {
    if (listening || thinking) return;

    setState(() {
      listening = true;
      statusText = isOnline ? "Listening..." : "Listening (offline)...";
    });

    voice.startListening(
      (text) async {
        if (!mounted) return;

        setState(() {
          listening = false;
          thinking = true;
          statusText = "Thinking...";
        });

        MemoryService.add("user", text);
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());

        LogService.add("User said: $text");

        String tone = ToneService.detectTone(text);
        String response;

        if (!isOnline) {
          response = LocalCommandService.process(text);
        } else {
          try {
            final res = await ApiService.post("chat", {
              "message": text,
              "deviceId": ApiService.deviceId,
            });
            response = res["reply"] ?? "I could not understand that.";
          } catch (e) {
            print("API error: $e");
            response = LocalCommandService.process(text);
          }
        }

        response = ToneService.modifyResponse(response, tone);

        MemoryService.add("assistant", response);
        LogService.add("Zeni replied: $response");

        if (!mounted) return;

        setState(() {
          thinking = false;
          statusText = "Tap mic to talk to Zeni";
        });

        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());

        tts.speak(response);
      },
      onOffline: () {
        if (!mounted) return;
        setState(() {
          listening = false;
          thinking = false;
          statusText = isOnline
              ? "Could not hear you. Try again."
              : "Offline. Say a local command.";
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = MemoryService.getMessages();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [

            // ── Top Bar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Zeni",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? "online" : "offline",
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      await ApiService.delete(
                          "history/${ApiService.deviceId}");
                      MemoryService.clear();
                      if (mounted) setState(() {});
                    },
                    child: Text(
                      "${MemoryService.count} memories",
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Zeni Bubble ───────────────────────────
            ZeniBubble(
              isListening: listening,
              isThinking: thinking,
              onClose: () {},
              text: statusText,
            ),

            const SizedBox(height: 12),

            // ── Chat History ──────────────────────────
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        "Say something to start talking with Zeni",
                        style: TextStyle(
                          color: Colors.white12,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return ChatMessage(
                          text: msg["content"] ?? "",
                          isUser: msg["role"] == "user",
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:
            listening ? Colors.redAccent : Colors.blueAccent,
        onPressed: startListening,
        child: Icon(
          listening ? Icons.stop : Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }
}