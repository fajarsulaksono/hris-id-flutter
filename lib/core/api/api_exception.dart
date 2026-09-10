import 'package:dio/dio.dart';

/// Peta galat HTTP / jaringan menjadi pesan yang siap ditampilkan.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException('Koneksi ke server melebihi batas waktu.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException('Tidak dapat terhubung ke server.');
    }

    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String) {
        return ApiException(message, statusCode: error.response?.statusCode);
      }

      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return ApiException(first.first.toString(),
              statusCode: error.response?.statusCode);
        }
      }
    }

    return ApiException(
      error.message ?? 'Terjadi kesalahan. Silakan coba lagi.',
      statusCode: error.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}