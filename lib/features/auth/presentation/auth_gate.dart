import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/home_shell.dart';
import '../application/auth_controller.dart';
import 'login_screen.dart';

/// Menentukan layar awal berdasarkan status sesi.
///
/// `unknown`        → menunggu pemulihan token dari secure storage (splash),
/// `unauthenticated` → layar login,
/// `authenticated`  → shell beranda.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);

    return switch (state.status) {
      AuthStatus.unknown => const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.authenticated => const HomeShell(),
    };
  }
}