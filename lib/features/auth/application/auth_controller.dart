import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState._(this.status, [this.token]);

  final AuthStatus status;
  final String? token;

  static const AuthState unknown = AuthState._(AuthStatus.unknown);
  static const AuthState unauthenticated = AuthState._(AuthStatus.unauthenticated);
  const AuthState.authenticated(String token)
      : this._(AuthStatus.authenticated, token);

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return AuthState.unknown;
  }

  Future<void> _restore() async {
    final token = await ref.read(tokenStorageProvider).read();
    state = token == null
        ? AuthState.unauthenticated
        : AuthState.authenticated(token);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final token = await ref
        .read(authRepositoryProvider)
        .login(username: username, password: password);
    await ref.read(tokenStorageProvider).write(token);
    state = AuthState.authenticated(token);
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } on ApiException {
      // Abaikan galat server saat logout; token dihapus lokal tetap.
    }
    await ref.read(tokenStorageProvider).clear();
    state = AuthState.unauthenticated;
  }
}