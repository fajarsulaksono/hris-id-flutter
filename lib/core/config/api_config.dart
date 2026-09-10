/// Konfigurasi aplikasi.
///
/// `API_BASE_URL` dapat di-override saat build, misalnya:
/// `flutter run --dart-define=API_BASE_URL=https://hris.example.com/api/v1`
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:9100/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}