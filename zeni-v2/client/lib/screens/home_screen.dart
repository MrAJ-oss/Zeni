import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/wake_word_service.dart';
import '../core/geofence_service.dart';
import '../core/contact_service.dart';
import '../widgets/voice_orb.dart';
import '../widgets/history_sheet.dart';
import '../widgets/feature_drawer.dart';
import '../widgets/visual_renderer.dart';
import 'memory_screen.dart';
import 'projects_screen.dart';
import 'devices_screen.dart';
import 'sentinel_screen.dart';
import 'teacher_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String deviceId;
  const HomeScreen({super.key, required this.deviceId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Lets just_audio play an in-memory MP3 byte array directly, without writing
// a temp file first.
class _BytesAudioSource extends StreamAudioSource {
  final List<int> bytes;
  _BytesAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  late final ZeniApiClient _api;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  WakeWordService? _wakeService;
  GeofenceService? _geofenceService;

  ZeniState _state = ZeniState.idle;
  String _liveText = '';
  String? _conversationId;
  final List<ChatMessage> _history = [];
  bool _speechReady = false;
  VisualPayload? _visual;

  @override
  void initState() {
    super.initState();
    _api = ZeniApiClient(widget.deviceId);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(onStatus: _onSpeechStatus);
    setState(() {});
    if (_speechReady) await _maybeArmWakeWord();
    await _maybeArmGeofence();
  }

  Future<void> _maybeArmGeofence() async {
    _geofenceService = GeofenceService(onEnteredHome: _handleGeofenceTrigger);
    await _geofenceService!.start();
  }

  Future<void> _handleGeofenceTrigger() async {
    if (_state != ZeniState.idle) return;
    try {
      final res = await _api.triggerGeofence(conversationId: _conversationId);
      _conversationId = res.conversationId;
      setState(() {
        _state = ZeniState.speaking;
        _liveText = res.reply;
        _history.add(ChatMessage('assistant', res.reply));
      });
      await _speak(res.reply);
      setState(() => _state = ZeniState.idle);
    } on ZeniApiException catch (e) {
      // COOLDOWN is expected/benign — she just triggered recently. Anything
      // else fails silently here since there's no user waiting on a reply.
      if (e.status != 'COOLDOWN') {
        setState(() => _liveText = _messageForStatus(e.status));
      }
    }
  }

  Future<void> _maybeArmWakeWord() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('wake_word_enabled') ?? false;
    if (!enabled) return;

    _wakeService = WakeWordService(
      _speech,
      onWakeDetected: () {
        if (_state == ZeniState.idle) _startListening();
      },
      onStopPhraseDetected: () {
        if (_state == ZeniState.speaking) {
          _tts.stop();
          _audioPlayer.stop();
          setState(() => _state = ZeniState.idle);
        }
      },
    );
    await _wakeService!.arm();
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_state == ZeniState.listening) _submit(_liveText);
    }
  }

  Future<void> _startListening() async {
    if (!_speechReady) return;
    _wakeService?.disarm();
    setState(() {
      _state = ZeniState.listening;
      _liveText = '';
      _visual = null;
    });
    await _speech.listen(onResult: (result) {
      setState(() => _liveText = result.recognizedWords);
    });
  }

  Future<void> _submit(String text) async {
    if (text.trim().isEmpty) {
      setState(() => _state = ZeniState.idle);
      _maybeArmWakeWord();
      return;
    }
    await _speech.stop();
    setState(() {
      _state = ZeniState.thinking;
      _history.add(ChatMessage('user', text));
    });

    try {
      final res = await _api.sendMessage(text, conversationId: _conversationId);
      _conversationId = res.conversationId;
      setState(() {
        _state = ZeniState.speaking;
        _liveText = res.reply;
        _visual = res.visual != null ? VisualPayload.fromJson(res.visual!) : null;
        _history.add(ChatMessage('assistant', res.reply, citations: res.citations));
      });
      await _speak(res.reply);
      setState(() => _state = ZeniState.idle);
      _maybeArmWakeWord();
      if (res.contactAction != null) {
        findAndCall(res.contactAction!['contactName'] ?? '');
      }
    } on ZeniApiException catch (e) {
      setState(() {
        _state = ZeniState.idle;
        _liveText = _messageForStatus(e.status);
      });
      _maybeArmWakeWord();
    }
  }

  void _stopSpeaking() {
    if (_state == ZeniState.speaking) {
      _tts.stop();
      _audioPlayer.stop();
      setState(() => _state = ZeniState.idle);
      _maybeArmWakeWord();
    }
  }

  // Server-side neural TTS (ElevenLabs/OpenRouter) when configured — real
  // voice, not the device's built-in robotic one. Falls back to on-device
  // TTS only if no server provider is set up, so the app still speaks.
  Future<void> _speak(String text) async {
    final result = await _api.speak(text);
    if (result != null && result['audioBase64'] != null) {
      final bytes = base64Decode(result['audioBase64']);
      await _audioPlayer.setAudioSource(_BytesAudioSource(bytes));
      await _audioPlayer.play();
      await _audioPlayer.playerStateStream.firstWhere((s) => s.processingState == ProcessingState.completed);
    } else {
      await _tts.speak(text);
    }
  }

  String _messageForStatus(String status) {
    switch (status) {
      case 'NOT_IMPLEMENTED':
        return 'The AI provider is not configured yet.';
      case 'AI_UNAVAILABLE':
      case 'PROVIDER_UNREACHABLE':
        return 'Cannot reach the AI provider right now.';
      case 'DEVICE_NOT_APPROVED':
        return 'This device has not been approved yet.';
      default:
        return 'Something went wrong.';
    }
  }

  void _openHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HistorySheet(messages: _history),
    );
  }

  @override
  void dispose() {
    _wakeService?.disarm();
    _geofenceService?.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0E),
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        child: FeatureDrawer(items: [
          FeatureItem('Sentinel', Icons.shield_outlined, () => _push(context, SentinelScreen(deviceId: widget.deviceId))),
          FeatureItem('Teacher', Icons.school_outlined, () => _push(context, TeacherScreen(deviceId: widget.deviceId))),
          FeatureItem('Projects', Icons.folder_outlined, () => _push(context, ProjectsScreen(deviceId: widget.deviceId))),
          FeatureItem('Memory', Icons.psychology_outlined, () => _push(context, MemoryScreen(deviceId: widget.deviceId))),
          FeatureItem('Devices', Icons.devices_outlined, () => _push(context, DevicesScreen(deviceId: widget.deviceId))),
          FeatureItem('Settings', Icons.settings_outlined, () => _push(context, const SettingsScreen())),
        ]),
      ),
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
            _openHistory();
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              Builder(builder: (context) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white38),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                );
              }),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (_state == ZeniState.idle) {
                    _startListening();
                  } else if (_state == ZeniState.speaking) {
                    _stopSpeaking();
                  }
                },
                child: VoiceOrb(state: _state),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _liveText.isEmpty ? _placeholderForState() : _liveText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
              ),
              if (_visual != null) VisualRenderer(payload: _visual!),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.keyboard_arrow_up, color: Colors.white24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _placeholderForState() {
    switch (_state) {
      case ZeniState.idle:
        return _speechReady ? 'Tap to talk' : 'Speech unavailable';
      case ZeniState.listening:
        return 'Listening...';
      case ZeniState.thinking:
        return '...';
      case ZeniState.speaking:
        return '';
    }
  }
}
