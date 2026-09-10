import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_repository.dart';
import 'notification_controller.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) =>
      PushNotificationService(ref, ref.read(notificationRepositoryProvider)),
);

class PushNotificationService {
  PushNotificationService(this._ref, this._repository);

  final Ref _ref;
  final NotificationRepository _repository;
  String? _registeredDeviceId;

  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) await _register(token);

      messaging.onTokenRefresh.listen(_register);
      FirebaseMessaging.onMessage.listen((_) {
        _ref.read(notificationControllerProvider.notifier).refresh();
      });
    } catch (_) {
      // Firebase configuration is optional for local development and tests.
    }
  }

  Future<void> unregister() async {
    final id = _registeredDeviceId;
    if (id == null) return;

    try {
      await _repository.unregisterDevice(id);
    } finally {
      _registeredDeviceId = null;
    }
  }

  Future<void> _register(String token) async {
    try {
      _registeredDeviceId = await _repository.registerDevice(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (_) {
      // Token registration is best-effort; login must remain usable offline.
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The operating system displays notification payloads while the app is closed.
}
