import 'package:flutter/material.dart';

class ZeniBubble extends StatelessWidget {
  final bool isListening;
  final bool isThinking;
  final VoidCallback onClose;
  final String text;

  const ZeniBubble({
    super.key,
    required this.isListening,
    required this.isThinking,
    required this.onClose,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    Color bubbleColor;
    if (isListening) {
      bubbleColor = Colors.blueAccent;
    } else if (isThinking) {
      bubbleColor = Colors.deepPurpleAccent;
    } else {
      bubbleColor = const Color(0xFF1A1A2E);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isListening ? 130 : 110,
          height: isListening ? 130 : 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bubbleColor,
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: bubbleColor.withOpacity(0.5),
                blurRadius: isListening ? 40 : 20,
                spreadRadius: isListening ? 10 : 4,
              ),
            ],
          ),
          child: Center(
            child: isThinking
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Z",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}