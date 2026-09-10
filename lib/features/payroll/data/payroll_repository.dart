import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'payroll.dart';

class PayrollRepository {
  PayrollRepository(this._dio);

  final Dio _dio;

  /// Fetches payslips on demand; no payroll payload is cached locally.
  Future<List<Payroll>> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/payrolls',
        queryParameters: {'ep': 99},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const ApiException('Respons payslip tidak valid.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(Payroll.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
