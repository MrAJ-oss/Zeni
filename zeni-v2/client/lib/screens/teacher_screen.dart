import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class TeacherScreen extends StatefulWidget {
  final String deviceId;
  const TeacherScreen({super.key, required this.deviceId});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final List<String> _subjects = ['Math', 'Science', 'History', 'English', 'Coding', 'Physics', 'Chemistry', 'Biology'];
  final List<String> _modes = ['chat', 'explain', 'solve', 'quiz'];
  String _subject = 'Math';
  String _mode = 'chat';
  final _inputController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  String? _conversationId;
  Map<String, dynamic>? _quiz;
  bool _busy = false;

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _busy = true;
    });

    final res = await http.post(
      Uri.parse('${ZeniConfig.apiBaseUrl}/teacher/message'),
      headers: {'Content-Type': 'application/json', 'x-device-id': widget.deviceId},
      body: jsonEncode({
        'message': text,
        'subject': _subject,
        'mode': _mode,
        if (_conversationId != null) 'conversationId': _conversationId,
      }),
    );
    final body = jsonDecode(res.body);
    setState(() {
      _busy = false;
      if (body['ok'] == true) {
        _conversationId = body['conversationId'];
        _messages.add({'role': 'assistant', 'content': body['reply']});
      } else {
        _messages.add({'role': 'assistant', 'content': 'Unavailable: ${body['status']}'});
      }
    });
  }

  Future<void> _generateQuiz() async {
    setState(() => _busy = true);
    final res = await http.post(
      Uri.parse('${ZeniConfig.apiBaseUrl}/teacher/quiz/generate'),
      headers: {'Content-Type': 'application/json', 'x-device-id': widget.deviceId},
      body: jsonEncode({'subject': _subject}),
    );
    final body = jsonDecode(res.body);
    setState(() {
      _busy = false;
      _quiz = body['ok'] == true ? body['quiz'] : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _subject,
                  dropdownColor: const Color(0xFF14161C),
                  items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) => setState(() => _subject = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _mode,
                  dropdownColor: const Color(0xFF14161C),
                  items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) => setState(() {
                    _mode = v!;
                    _quiz = null;
                  }),
                ),
              ),
            ]),
          ),
          if (_mode == 'quiz')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ElevatedButton(onPressed: _busy ? null : _generateQuiz, child: const Text('New question')),
            ),
          if (_quiz != null) _QuizCard(quiz: _quiz!),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF2A2E38) : const Color(0xFF1E2129),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(m['content']!, style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Ask something'),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _busy ? null : _send),
            ]),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const _QuizCard({required this.quiz});
  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final options = (widget.quiz['options'] as List).cast<String>();
    final correctIndex = widget.quiz['correctIndex'] as int;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF14161C), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.quiz['question'], style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 10),
        ...List.generate(options.length, (i) {
          final selected = _selected == i;
          Color? color;
          if (_selected != null) {
            if (i == correctIndex) color = const Color(0xFF4FE0C1);
            else if (selected) color = const Color(0xFFFF6B6B);
          }
          return ListTile(
            dense: true,
            tileColor: color?.withOpacity(0.15),
            title: Text(options[i], style: TextStyle(color: color ?? Colors.white70)),
            onTap: _selected == null ? () => setState(() => _selected = i) : null,
          );
        }),
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(widget.quiz['explanation'] ?? '', style: const TextStyle(color: Colors.white54)),
          ),
      ]),
    );
  }
}
