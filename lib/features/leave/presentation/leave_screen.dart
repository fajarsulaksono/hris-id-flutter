import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder.dart';

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Cuti',
      icon: Icons.event_available,
    );
  }
}