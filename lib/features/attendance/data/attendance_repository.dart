import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import 'attendance.dart';

/// Repositori absensi terhadap endpoint `/attendances` backend.
///
/// Untuk karyawan, backend mem-scope otomatis ke record milik sendiri
/// (ability `view_my_attendance` / `manage_my_attendance`).
class AttendanceRepository {
  AttendanceRepository(this._dio);

  final Dio _dio;

  /// Riwayat absensi satu bulan untuk karyawan yang login.
  ///
  /// Ambil halaman terbaru (tanggal menurun) lalu saring berdasarkan bulan
  /// di sisi klien karena API tidak punya filter rentang tanggal.
  Future<List<Attendance>> listForMonth(int year, int month) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/attendances',
        queryParameters: {'ep': 99},
      );

      final data = response.data?['data'];
      if (data is! List) {
        throw const ApiException('Respons absensi tidak valid.');
      }

      final records = data
          .whereType<Map<String, dynamic>>()
          .map(Attendance.fromJson)
          .where((record) =>
              record.attendanceDate.year == year &&
              record.attendanceDate.month == month)
          .toList();

      records.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

      return records;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Check-in hari ini. Backend menolak duplikat tanggal (422).
  Future<Attendance> clockIn({
    required DateTime date,
    required String time,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/attendances',
        data: {
          'attendance_date': _formatDate(date),
          'check_in': time,
        },
      );

      final data = response.data?['data'];
      if (data is! Map) {
        throw const ApiException('Respons check-in tidak valid.');
      }

      return Attendance.fromJson(data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Check-out untuk catatan yang sudah check-in.
  Future<Attendance> clockOut(Attendance attendance, {required String time}) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/attendances/${attendance.id}',
        data: {'check_out': time},
      );

      final data = response.data?['data'];
      if (data is! Map) {
        throw const ApiException('Respons check-out tidak valid.');
      }

      return Attendance.fromJson(data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');

    return '${date.year}-$mm-$dd';
  }
}