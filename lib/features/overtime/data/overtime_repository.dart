import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'overtime.dart';

class OvertimeRepository {
  OvertimeRepository(this._dio);

  final Dio _dio;

  Future<List<Overtime>> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/overtimes',
        queryParameters: {'ep': 99},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const ApiException('Respons lembur tidak valid.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(Overtime.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Overtime> create({
    required DateTime date,
    required String startHour,
    required String endHour,
    String? description,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/overtimes',
        data: {
          'overtime_date': _formatDate(date),
          'start_hour': startHour,
          'end_hour': endHour,
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
        },
      );
      final data = response.data?['data'];
      if (data is! Map) {
        throw const ApiException('Respons pengajuan lembur tidak valid.');
      }

      return Overtime.fromJson(data as Map<String, dynamic>);
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
