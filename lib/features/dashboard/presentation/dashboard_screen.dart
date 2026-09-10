import 'package:flutter/material.dart';

import '../../overtime/presentation/overtime_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Lembur'),
              subtitle: const Text('Ajukan dan lihat status lembur'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OvertimeScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}