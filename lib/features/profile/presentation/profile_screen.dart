import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/feature_placeholder.dart';
import '../../auth/application/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeaturePlaceholder(
      title: 'Profil',
      icon: Icons.person_outline,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Keluar',
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).logout();
          },
        ),
      ],
    );
  }
}