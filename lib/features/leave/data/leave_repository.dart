import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'leave.dart';

class LeaveRepository {
  LeaveRepository(this._dio);

  final Dio _dio;

  Future<List<Leave>> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/leaves',
        queryParameters: {'ep': 99},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const ApiException('Respons cuti tidak valid.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(Leave.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<LeaveReason>> listReasons() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reasons',
        queryParameters: {'type': 'l', 'ep': 99},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const ApiException('Respons alasan cuti tidak valid.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(LeaveReason.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Leave> create({
    required DateTime date,
    required String reasonId,
    required int amount,
    String? description,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/leaves',
        data: {
          'leave_date': _formatDate(date),
          'reason_id': reasonId,
          'amount': amount,
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
        },
      );
      final data = response.data?['data'];
      if (data is! Map) {
        throw const ApiException('Respons pengajuan cuti tidak valid.');
      }

      return Leave.fromJson(data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
