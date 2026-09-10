import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/notification.dart';
import '../data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(dioProvider)),
);

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, List<AppNotification>>(
      NotificationController.new,
    );

class NotificationController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() =>
      ref.read(notificationRepositoryProvider).list();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).list(),
    );
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;

    final updated = await ref
        .read(notificationRepositoryProvider)
        .markRead(notification.id);
    if (!state.hasValue) return;
    final current = state.value;
    if (current == null) return;

    state = AsyncData([
      for (final item in current) item.id == updated.id ? updated : item,
    ]);
  }
}
