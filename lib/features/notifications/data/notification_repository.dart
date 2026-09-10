import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'notification.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<List<AppNotification>> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'ep': 99},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const ApiException('Respons notifikasi tidak valid.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AppNotification> markRead(String id) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>('/notifications/$id/read');
      final data = response.data?['data'];
      if (data is! Map) {
        throw const ApiException('Respons notifikasi tidak valid.');
      }

      return AppNotification.fromJson(data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> registerDevice({
    required String token,
    required String platform,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/device',
        data: {'token': token, 'platform': platform},
      );
      final id = response.data?['data']?['id'];
      if (id is! String || id.isEmpty) {
        throw const ApiException('Respons registrasi device tidak valid.');
      }

      return id;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> unregisterDevice(String id) async {
    try {
      await _dio.delete<void>('/auth/device/$id');
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
