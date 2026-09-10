import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/preferences.dart';
import '../data/auth_repository.dart';
import '../data/user.dart';
import '../../notifications/application/push_notification_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState._(this.status, [this.token, this.user]);

  final AuthStatus status;
  final String? token;
  final User? user;

  static const AuthState unknown = AuthState._(AuthStatus.unknown);
  static const AuthState unauthenticated = AuthState._(
    AuthStatus.unauthenticated,
  );

  const AuthState.authenticated(String token, [User? user])
    : this._(AuthStatus.authenticated, token, user);

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return AuthState.unknown;
  }

  /// Memulihkan sesi dari secure storage, lalu memvalidasinya via `/auth/me`.
  Future<void> _restore() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null) {
      state = AuthState.unauthenticated;
      return;
    }

    state = AuthState.authenticated(token);
    await _refreshUser(token);
    if (state.isAuthenticated) {
      await ref.read(pushNotificationServiceProvider).initialize();
    }

    final biometricEnabled = await ref
        .read(biometricPreferenceProvider)
        .isEnabled();
    if (biometricEnabled) {
      ref.read(unlockControllerProvider.notifier).lock();
    }
  }

  /// Menyegarkan profil pengguna; 401 berarti sesi tidak valid → logout lokal.
  Future<void> _refreshUser(String token) async {
    try {
      final user = await ref.read(authRepositoryProvider).me();
      if (state.token == token) {
        state = AuthState.authenticated(token, user);
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _signOutLocal();
      }

      // 403 ke bawah / galat jaringan: tetap login, profil diisi saat ada koneksi.
    }
  }

  Future<void> refresh() async {
    final token = state.token;
    if (token == null) {
      return;
    }
    await _refreshUser(token);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(username: username, password: password);
    await ref.read(tokenStorageProvider).write(result.token);
    ref.read(unlockControllerProvider.notifier).unlock();
    state = AuthState.authenticated(result.token, result.user);
    await ref.read(pushNotificationServiceProvider).initialize();
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } on ApiException {
      // Abaikan galat server saat logout; token dihapus lokal tetap.
    }
    await _signOutLocal();
  }

  Future<void> _signOutLocal() async {
    await ref.read(pushNotificationServiceProvider).unregister();
    await ref.read(tokenStorageProvider).clear();
    ref.read(unlockControllerProvider.notifier).unlock();
    state = AuthState.unauthenticated;
  }
}

/// Kunci pembuka biometrik: `true` = layar kunci biometrik ditampilkan.
final unlockControllerProvider = NotifierProvider<UnlockController, bool>(
  UnlockController.new,
);

class UnlockController extends Notifier<bool> {
  @override
  bool build() => false;

  void lock() => state = true;

  void unlock() => state = false;
}
