import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../security/biometric_service.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());

final biometricPreferenceProvider = Provider<BiometricPreference>(
  (ref) => const BiometricPreference(),
);

/// Dukungan biometrik pada perangkat saat ini.
final biometricSupportedProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricServiceProvider).isAvailable,
);

/// Preferensi "buka kunci dengan biometrik" (disimpan di secure storage).
class BiometricPreference {
  const BiometricPreference({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _enabledKey = 'biometric_enabled';

  final FlutterSecureStorage _storage;

  Future<bool> isEnabled() async => await _storage.read(key: _enabledKey) == '1';

  Future<void> setEnabled(bool value) =>
      _storage.write(key: _enabledKey, value: value ? '1' : '0');
}

/// Status preferensi biometrik yang di-watch oleh layar.
final biometricEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricPreferenceProvider).isEnabled(),
);