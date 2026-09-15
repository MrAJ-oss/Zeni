import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ZeniApiException implements Exception {
  final String status;
  final String? error;
  ZeniApiException(this.status, this.error);
  @override
  String toString() => 'ZeniApiException($status: $error)';
}

class ChatResult {
  final String conversationId;
  final String reply;
  final Map<String, dynamic>? visual;
  final List<dynamic>? citations;
  final Map<String, dynamic>? contactAction;
  ChatResult({required this.conversationId, required this.reply, this.visual, this.citations, this.contactAction});
}

class ZeniApiClient {
  final String deviceId;
  ZeniApiClient(this.deviceId);

  Uri _uri(String path) => Uri.parse('${ZeniConfig.apiBaseUrl}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-device-id': deviceId,
      };

  Future<ChatResult> sendMessage(String message, {String? conversationId}) async {
    final res = await http.post(
      _uri('/chat/message'),
      headers: _headers,
      body: jsonEncode({'message': message, if (conversationId != null) 'conversationId': conversationId}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['ok'] != true) {
      throw ZeniApiException(body['status'] ?? 'UNKNOWN', body['error']);
    }
    return ChatResult(
      conversationId: body['conversationId'],
      reply: body['reply'] ?? '',
      visual: body['visual'],
      citations: body['citations'],
      contactAction: body['contactAction'],
    );
  }

  Future<ChatResult> triggerGeofence({String? conversationId}) async {
    final res = await http.post(
      _uri('/automation/geofence-trigger'),
      headers: _headers,
      body: jsonEncode({if (conversationId != null) 'conversationId': conversationId}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['ok'] != true) {
      throw ZeniApiException(body['status'] ?? 'UNKNOWN', body['error']);
    }
    return ChatResult(conversationId: body['conversationId'], reply: body['reply'] ?? '');
  }

  // Returns base64 audio (mp3) + format, or throws if no TTS provider is
  // configured server-side. Caller decides how to play it.
  Future<Map<String, dynamic>?> speak(String text, {String? languageCode}) async {
    final res = await http.post(
      _uri('/voice/speak'),
      headers: _headers,
      body: jsonEncode({'text': text, if (languageCode != null) 'languageCode': languageCode}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['ok'] != true) return null; // caller falls back to device TTS
    return body;
  }

  Future<Map<String, dynamic>> health() async {
    final res = await http.get(_uri('/health'));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
