import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../data/overtime.dart';
import '../data/overtime_repository.dart';

final overtimeRepositoryProvider = Provider<OvertimeRepository>(
  (ref) => OvertimeRepository(ref.watch(dioProvider)),
);

final overtimeControllerProvider =
    AsyncNotifierProvider<OvertimeController, List<Overtime>>(
      OvertimeController.new,
    );

class OvertimeController extends AsyncNotifier<List<Overtime>> {
  @override
  Future<List<Overtime>> build() => ref.read(overtimeRepositoryProvider).list();

  Future<void> submit({
    required DateTime date,
    required String startHour,
    required String endHour,
    String? description,
  }) async {
    if (_dateOnly(date).isBefore(_dateOnly(DateTime.now()))) {
      throw const ApiException('Tanggal lembur tidak boleh sebelum hari ini.');
    }

    if (_toMinutes(endHour) <= _toMinutes(startHour)) {
      throw const ApiException('Jam selesai harus setelah jam mulai.');
    }

    final repository = ref.read(overtimeRepositoryProvider);
    await repository.create(
      date: date,
      startHour: startHour,
      endHour: endHour,
      description: description,
    );
    state = AsyncData(await repository.list());
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _toMinutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
