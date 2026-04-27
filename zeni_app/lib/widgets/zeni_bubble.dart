import 'package:flutter/material.dart';

class ZeniBubble extends StatelessWidget {
  final bool isListening;

  const ZeniBubble({super.key, required this.isListening});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isListening ? 120 : 80,
      height: isListening ? 120 : 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isListening
              ? [Colors.blue, Colors.purple]
              : [Colors.grey, Colors.black],
        ),
      ),
    );
  }
}