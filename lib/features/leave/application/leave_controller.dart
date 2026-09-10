import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

import '../data/leave.dart';
import '../data/leave_repository.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>(
  (ref) => LeaveRepository(ref.watch(dioProvider)),
);

final leaveControllerProvider =
    AsyncNotifierProvider<LeaveController, List<Leave>>(LeaveController.new);

class LeaveController extends AsyncNotifier<List<Leave>> {
  @override
  Future<List<Leave>> build() => ref.read(leaveRepositoryProvider).list();

  Future<List<LeaveReason>> reasons() =>
      ref.read(leaveRepositoryProvider).listReasons();

  Future<void> submit({
    required DateTime date,
    required String reasonId,
    required int amount,
    String? description,
  }) async {
    if (_dateOnly(date).isBefore(_dateOnly(DateTime.now()))) {
      throw const ApiException('Tanggal cuti tidak boleh sebelum hari ini.');
    }

    final repository = ref.read(leaveRepositoryProvider);
    await repository.create(
      date: date,
      reasonId: reasonId,
      amount: amount,
      description: description,
    );
    state = AsyncData(await repository.list());
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
