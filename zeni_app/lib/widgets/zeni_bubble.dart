import 'package:flutter/material.dart';

class ZeniBubble extends StatefulWidget {
  final VoidCallback onClose;

  const ZeniBubble({super.key, required this.onClose, required bool isListening});

  @override
  State<ZeniBubble> createState() => _ZeniBubbleState();
}

class _ZeniBubbleState extends State<ZeniBubble> {
  Offset position = const Offset(120, 400);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
        },
        onTap: widget.onClose,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
            ),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.blueAccent.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: const Icon(Icons.graphic_eq, color: Colors.white, size: 35),
        ),
      ),
    );
  }
}