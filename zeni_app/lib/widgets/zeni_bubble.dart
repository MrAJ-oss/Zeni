import 'package:flutter/material.dart';

class ZeniBubble extends StatelessWidget {
  final bool isListening;
  final VoidCallback onClose;

  const ZeniBubble({
    super.key,
    required this.isListening,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isListening ? Colors.blueAccent : Colors.black,
          ),
          child: const Center(
            child: Text(
              "Zeni",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isListening ? "Listening..." : "Ready",
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}