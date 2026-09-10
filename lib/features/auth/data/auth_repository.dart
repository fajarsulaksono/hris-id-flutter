import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'user.dart';

/// Hasil login: token Sanctum + profil pengguna.
class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final User user;
}

/// Repositori auth terhadap endpoint `/auth/*` backend (hris-id-laravel).
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Login mengembalikan token Sanctum beserta profil pengguna.
  Future<AuthResult> login({
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
      final userJson = response.data?['user'];
      if (token is! String || token.isEmpty || userJson is! Map) {
        throw const ApiException('Respons login tidak valid.');
      }

      return AuthResult(token: token, user: User.fromJson(userJson as Map<String, dynamic>));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Profil pengguna saat ini (`/auth/me`).
  Future<User> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');

      final data = response.data?['data'];
      if (data is! Map) {
        throw const ApiException('Respons profil tidak valid.');
      }

      return User.fromJson(data as Map<String, dynamic>);
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