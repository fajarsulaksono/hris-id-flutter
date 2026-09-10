import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/home_shell.dart';
import '../application/auth_controller.dart';
import 'biometric_gate_screen.dart';
import 'login_screen.dart';

/// Menentukan layar awal berdasarkan status sesi.
///
/// `unknown`          → menunggu pemulihan token (splash),
/// `unauthenticated`  → layar login,
/// `authenticated`    → beranda (atau layar kunci biometrik bila aktif).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final locked = ref.watch(unlockControllerProvider);

    return switch (state.status) {
      AuthStatus.unknown => const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.authenticated when locked => const BiometricGateScreen(),
      AuthStatus.authenticated => const HomeShell(),
    };
  }
}