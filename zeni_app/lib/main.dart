// ignore_for_file: library_private_types_in_public_api, duplicate_ignore, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:zeni_app/services/voice_biometrics.dart';
import 'dart:convert';

// ignore: duplicate_import
import 'services/voice_biometrics.dart';
import 'approval_page.dart';

void main() {
  runApp(ZeniApp());
}

// ignore: use_key_in_widget_constructors
class ZeniApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

/* ================= AUTH ================= */

class AuthGate extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool isSetup = false;

  @override
  void initState() {
    super.initState();
    check();
  }

  void check() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSetup = prefs.getBool("setup") ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isSetup ? LoginPage() : SetupPage();
  }
}

/* ================= SETUP ================= */

class SetupPage extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _SetupPageState createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  TextEditingController pass = TextEditingController();
  TextEditingController name = TextEditingController();

  VoiceBiometrics vb = VoiceBiometrics();

  void setup() async {
    final prefs = await SharedPreferences.getInstance();

    String deviceId = DateTime.now().millisecondsSinceEpoch.toString();

    await prefs.setString("password", pass.text);
    await prefs.setString("device_name", name.text);
    await prefs.setString("deviceId", deviceId);
    await prefs.setBool("setup", true);

    // 🔥 save voice sample (simple)
    await vb.saveSample("hey zeni");

    await http.post(
      Uri.parse("http://10.241.123.58:3000/api/device/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "deviceId": deviceId,
        "name": name.text
      }),
    );

    Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context, MaterialPageRoute(builder: (_) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Setup ZENI", style: TextStyle(fontSize: 22)),
            TextField(controller: pass, decoration: InputDecoration(labelText: "Password")),
            TextField(controller: name, decoration: InputDecoration(labelText: "Device Name")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: setup, child: Text("Continue"))
          ],
        ),
      ),
    );
  }
}

/* ================= LOGIN ================= */

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController input = TextEditingController();

  void login() async {
    final prefs = await SharedPreferences.getInstance();

    if (input.text == prefs.getString("password")) {
      Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context, MaterialPageRoute(builder: (_) => HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Enter Password"),
            TextField(controller: input),
            SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: Text("Login"))
          ],
        ),
      ),
    );
  }
}

/* ================= HOME ================= */

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late stt.SpeechToText speech;
  late FlutterTts tts;

  VoiceBiometrics vb = VoiceBiometrics();

  bool isListening = false;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    tts = FlutterTts();
    startListening();
  }

  void startListening() async {
    bool available = await speech.initialize();

    if (available) {
      setState(() => isListening = true);

      speech.listen(onResult: (result) {
        process(result.recognizedWords);
      });
    }
  }

  void process(String text) async {
    text = text.toLowerCase();

    if (text.contains("hey zeni")) {
      bool isVerified = await vb.verify(text);

      sendCommand(text, isVerified);
    }
  }

  void sendCommand(String text, bool isVerified) async {
    final prefs = await SharedPreferences.getInstance();
    String deviceId = prefs.getString("deviceId")!;

    final res = await http.post(
      Uri.parse("http://10.241.123.58:3000/api/voice"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "text": text,
        "deviceId": deviceId,
        "isVerified": isVerified
      }),
    );

    final data = jsonDecode(res.body);
    speak(data["reply"]);
  }

  void speak(String text) async {
    await tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ZENI"),
        actions: [
          IconButton(
            icon: Icon(Icons.devices),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ApprovalPage()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Text(
          isListening ? "🎤 Listening..." : "Not Listening",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}