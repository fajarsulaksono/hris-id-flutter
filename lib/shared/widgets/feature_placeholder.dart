import 'package:flutter/material.dart';

/// Kanvas default untuk fitur yang belum diimplementasikan.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.icon,
    this.actions = const [],
  });

  final String title;
  final IconData icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Fitur $title sedang dikembangkan.', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}