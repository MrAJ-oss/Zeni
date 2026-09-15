import 'package:flutter/material.dart';

class ChatMessage {
  final String role;
  final String content;
  final List<dynamic>? citations;
  ChatMessage(this.role, this.content, {this.citations});
}

class HistorySheet extends StatelessWidget {
  final List<ChatMessage> messages;
  const HistorySheet({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.2,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF14161C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final m = messages[i];
              final isUser = m.role == 'user';
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.content, style: const TextStyle(color: Colors.white, fontSize: 15)),
                      if (m.citations != null && m.citations!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            m.citations!.map((c) => c['title'] ?? c['url']).join(' · '),
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
