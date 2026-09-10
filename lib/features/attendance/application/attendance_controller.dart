import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../data/attendance.dart';
import '../data/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(ref.watch(dioProvider)),
);

/// Riwayat absensi bulan berjalan (diurutkan tanggal menurun).
final attendanceControllerProvider =
    AsyncNotifierProvider<AttendanceController, List<Attendance>>(
  AttendanceController.new,
);

class AttendanceController extends AsyncNotifier<List<Attendance>> {
  @override
  Future<List<Attendance>> build() {
    final now = DateTime.now();

    return ref
        .read(attendanceRepositoryProvider)
        .listForMonth(now.year, now.month);
  }

  /// Check-in sekarang, lalu muat ulang riwayat. Galat (mis. offline)
  /// dilempar ke pemanggil layar untuk ditampilkan sebagai SnackBar.
  Future<void> clockIn() async {
    final now = DateTime.now();
    final repository = ref.read(attendanceRepositoryProvider);

    await repository.clockIn(date: now, time: _format(now));
    await _reload(now, repository);
  }

  /// Check-out untuk catatan yang sudah check-in hari ini.
  Future<void> clockOut(Attendance today) async {
    final now = DateTime.now();
    final repository = ref.read(attendanceRepositoryProvider);

    await repository.clockOut(today, time: _format(now));
    await _reload(now, repository);
  }

  /// Buang data lama agar tombol check-in/out dan riwayat ter-update.
  Future<void> refresh() async {
    final now = DateTime.now();
    await _reload(now, ref.read(attendanceRepositoryProvider));
  }

  Future<void> _reload(DateTime now, AttendanceRepository repository) async {
    try {
      state = AsyncData(await repository.listForMonth(now.year, now.month));
    } on ApiException {
      // Galat saat muat ulang: biarkan data lama tetap tampil karena
      // penyebab (mis. offline) sudah dilempar dari aksi yang memicunya.
    }
  }

  static String _format(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');

    return '$hh:$mm';
  }
}