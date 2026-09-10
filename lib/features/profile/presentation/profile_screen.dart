import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/preferences.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: user == null
          ? _ProfileMissing(onRetry: () => ref.read(authControllerProvider.notifier).refresh())
          : _ProfileBody(user: user),
    );
  }
}

class _ProfileMissing extends StatelessWidget {
  const _ProfileMissing({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Profil belum termuat.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricSupported = ref.watch(biometricSupportedProvider).asData?.value ?? false;
    final biometricEnabled = ref.watch(biometricEnabledProvider).asData?.value ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(user.fullName.isNotEmpty ? user.fullName[0] : '?'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(user.email, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _InfoRow(label: 'Username', value: user.username),
                _InfoRow(label: 'NIK', value: user.code),
                _InfoRow(label: 'Perusahaan', value: user.companyName ?? '-'),
                _InfoRow(label: 'Departemen', value: user.departmentName ?? '-'),
                _InfoRow(label: 'Jabatan', value: user.jobTitleName ?? '-'),
                _InfoRow(label: 'Jenjang', value: user.jobLevelName ?? '-'),
                if (user.roles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        for (final role in user.roles)
                          Chip(
                            label: Text(role),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Buka kunci dengan biometrik'),
            subtitle: const Text('Diminta saat membuka aplikasi'),
            activeThumbColor: Theme.of(context).colorScheme.primary,
            value: biometricEnabled,
            onChanged: biometricSupported
                ? (value) async {
                    await ref.read(biometricPreferenceProvider).setEnabled(value);
                    ref.invalidate(biometricEnabledProvider);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}