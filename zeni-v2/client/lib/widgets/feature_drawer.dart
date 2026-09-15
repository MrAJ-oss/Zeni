import 'package:flutter/material.dart';

class FeatureItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  FeatureItem(this.label, this.icon, this.onTap);
}

class FeatureDrawer extends StatelessWidget {
  final List<FeatureItem> items;
  const FeatureDrawer({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF0E0F13),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: items
              .map((item) => ListTile(
                    leading: Icon(item.icon, color: Colors.white70),
                    title: Text(item.label, style: const TextStyle(color: Colors.white)),
                    onTap: item.onTap,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
