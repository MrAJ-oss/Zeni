import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VisualPayload {
  final String visualType;
  final String? title;
  final Map<String, dynamic> data;
  VisualPayload({required this.visualType, this.title, required this.data});

  factory VisualPayload.fromJson(Map<String, dynamic> json) => VisualPayload(
        visualType: json['visualType'],
        title: json['title'],
        data: Map<String, dynamic>.from(json['data'] ?? {}),
      );
}

class VisualRenderer extends StatelessWidget {
  final VisualPayload payload;
  const VisualRenderer({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF14161C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildByType(),
    );
  }

  Widget _buildByType() {
    switch (payload.visualType) {
      case 'stat':
        return _StatView(title: payload.title, data: payload.data);
      case 'list':
        return _ListView(title: payload.title, data: payload.data);
      case 'comparison':
        return _ComparisonView(title: payload.title, data: payload.data);
      case 'status':
        return _StatusView(title: payload.title, data: payload.data);
      case 'steps':
        return _StepsView(title: payload.title, data: payload.data);
      case 'map':
        return _MapView(title: payload.title, data: payload.data);
      default:
        return Text('Unsupported visual type: ${payload.visualType}', style: const TextStyle(color: Colors.white38));
    }
  }
}

class _StatView extends StatelessWidget {
  final String? title;
  final Map<String, dynamic> data;
  const _StatView({this.title, required this.data});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null) Text(title!, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      Text('${data['value']}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _ListView extends StatelessWidget {
  final String? title;
  final Map<String, dynamic> data;
  const _ListView({this.title, required this.data});
  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List?) ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null) Text(title!, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      const SizedBox(height: 8),
      ...items.map((i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text('- $i', style: const TextStyle(color: Colors.white, fontSize: 15)),
          )),
    ]);
  }
}

class _ComparisonView extends StatelessWidget {
  final String? title;
  final Map<String, dynamic> data;
  const _ComparisonView({this.title, required this.data});
  @override
  Widget build(BuildContext context) {
    final left = data['left'] as Map<String, dynamic>? ?? {};
    final right = data['right'] as Map<String, dynamic>? ?? {};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null) Text(title!, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _comparisonColumn(left)),
        Container(width: 1, height: 60, color: Colors.white12),
        Expanded(child: _comparisonColumn(right)),
      ]),
    ]);
  }

  Widget _comparisonColumn(Map<String, dynamic> col) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${col['label'] ?? ''}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        Text('${col['value'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 18)),
      ]),
    );
  }
}

class _StatusView extends StatelessWidget {
  final String? title;
  final Map<String, dynamic> data;
  const _StatusView({this.title, required this.data});
  @override
  Widget build(BuildContext context) {
    final ok = data['ok'] == true;
    return Row(children: [
      Icon(ok ? Icons.check_circle : Icons.error, color: ok ? const Color(0xFF4FE0C1) : const Color(0xFFFF6B6B)),
      const SizedBox(width: 10),
      Expanded(child: Text('${data['message'] ?? title ?? ''}', style: const TextStyle(color: Colors.white))),
    ]);
  }
}

class _StepsView extends StatelessWidget {
  final String? title;
  final Map<String, dynamic> data;
  const _StepsView({this.title, required this.data});
  @override
  Widget build(BuildContext context) {
    final steps = (data['steps'] as List?) ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null) Text(title!, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      const SizedBox(height: 8),
      ...steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('${e.key + 1}. ${e.value}', style: const TextStyle(color: Colors.white, fontSize: 15)),
          )),
    ]);
  }
}

class _MapView extends StatelessWidget {
  final String? title;
  final Map<String, dynamic> data;
  const _MapView({this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final lat = data['lat'];
    final lng = data['lng'];
    final card = data['card'] as String?;
    // Static preview tile — no Maps SDK/API key wired in yet, so this isn't
    // an interactive globe. Tapping opens the device's real maps app, which
    // IS fully interactive.
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null) Text(title!, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=13&size=400x200&markers=$lat,$lng,red-pushpin',
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 160,
            color: const Color(0xFF1E2129),
            alignment: Alignment.center,
            child: const Text('Map preview unavailable', style: TextStyle(color: Colors.white38)),
          ),
        ),
      ),
      if (card != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(card, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse('geo:$lat,$lng?q=$lat,$lng')),
          child: const Text('Open in Maps', style: TextStyle(color: Color(0xFF4FA3FF), fontSize: 13)),
        ),
      ),
    ]);
  }
}
