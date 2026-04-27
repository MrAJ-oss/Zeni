import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  final VoidCallback onTap;

  const MicButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      child: const Icon(Icons.mic),
    );
  }
}