import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';

/// Repositori auth terhadap endpoint `/auth/*` backend (hris-id-laravel).
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Login mengembalikan Sanctum plain-text token.
  Future<String> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'device_name': 'hris-id-mobile',
        },
      );

      final token = response.data?['token'];
      if (token is! String || token.isEmpty) {
        throw const ApiException('Respons login tidak valid.');
      }

      return token;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<Map<String, dynamic>>('/auth/logout');
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}