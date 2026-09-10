import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../application/notification_controller.dart';
import '../data/notification.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorNotice(
          message: error is ApiException
              ? error.message
              : 'Gagal memuat notifikasi.',
          onRetry: () => ref.read(notificationControllerProvider.notifier).refresh(),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () =>
              ref.read(notificationControllerProvider.notifier).refresh(),
          child: list.isEmpty
              ? const _EmptyNotice()
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _NotificationTile(
                    notification: list[index],
                    onTap: () => ref
                        .read(notificationControllerProvider.notifier)
                        .markRead(list[index]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead
          ? null
          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: ListTile(
        leading: Icon(
          notification.type == 'payroll_processed'
              ? Icons.account_balance_wallet_outlined
              : Icons.notifications_outlined,
        ),
        title: Text(notification.title),
        subtitle: Text(notification.message),
        trailing: notification.isRead
            ? null
            : const Icon(Icons.circle, size: 10),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 100),
          child: Center(child: Text('Belum ada notifikasi.')),
        ),
      ],
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
