import 'package:flutter/material.dart';

/// Tema global aplikasi HRIS (Material 3, seed biru).
class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
      );
}