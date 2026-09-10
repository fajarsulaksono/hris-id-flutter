import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Absensi',
      icon: Icons.access_time_filled,
    );
  }
}