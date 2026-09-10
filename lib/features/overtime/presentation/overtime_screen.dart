import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder.dart';

class OvertimeScreen extends StatelessWidget {
  const OvertimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Lembur',
      icon: Icons.schedule,
    );
  }
}