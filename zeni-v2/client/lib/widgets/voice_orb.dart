import 'package:flutter/material.dart';

enum ZeniState { idle, listening, thinking, speaking }

class VoiceOrb extends StatefulWidget {
  final ZeniState state;
  const VoiceOrb({super.key, required this.state});

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorForState(ZeniState s) {
    switch (s) {
      case ZeniState.idle:
        return const Color(0xFF3A3F4B);
      case ZeniState.listening:
        return const Color(0xFF4FA3FF);
      case ZeniState.thinking:
        return const Color(0xFF9B6BFF);
      case ZeniState.speaking:
        return const Color(0xFF4FE0C1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.state == ZeniState.idle
            ? 1.0
            : 1.0 + (_controller.value * 0.08);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_colorForState(widget.state).withOpacity(0.9), _colorForState(widget.state).withOpacity(0.15)],
              ),
            ),
          ),
        );
      },
    );
  }
}
