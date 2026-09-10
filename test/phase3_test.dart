import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hris_id_flutter/core/api/api_exception.dart';
import 'package:hris_id_flutter/features/leave/application/leave_controller.dart';
import 'package:hris_id_flutter/features/leave/data/leave.dart';
import 'package:hris_id_flutter/features/leave/data/leave_repository.dart';
import 'package:hris_id_flutter/features/overtime/application/overtime_controller.dart';
import 'package:hris_id_flutter/features/overtime/data/overtime.dart';
import 'package:hris_id_flutter/features/overtime/data/overtime_repository.dart';

class _FakeLeaveRepository extends LeaveRepository {
  _FakeLeaveRepository() : super(Dio(BaseOptions()));

  final reason = const LeaveReason(id: 'reason-1', name: 'Cuti Tahunan');
  List<Leave> records = [];

  @override
  Future<List<Leave>> list() async => records;

  @override
  Future<List<LeaveReason>> listReasons() async => [reason];

  @override
  Future<Leave> create({
    required DateTime date,
    required String reasonId,
    required int amount,
    String? description,
  }) async {
    final request = Leave(
      id: 'leave-${records.length + 1}',
      leaveDate: date,
      reasonId: reasonId,
      amount: amount,
      reason: reason,
      description: description,
    );
    records = [request, ...records];
    return request;
  }
}

class _FakeOvertimeRepository extends OvertimeRepository {
  _FakeOvertimeRepository() : super(Dio(BaseOptions()));

  List<Overtime> records = [];

  @override
  Future<List<Overtime>> list() async => records;

  @override
  Future<Overtime> create({
    required DateTime date,
    required String startHour,
    required String endHour,
    String? description,
  }) async {
    final request = Overtime(
      id: 'overtime-${records.length + 1}',
      overtimeDate: date,
      startHour: startHour,
      endHour: endHour,
      description: description,
      status: 'approved',
    );
    records = [request, ...records];
    return request;
  }
}

void main() {
  test('cuti: submit menambahkan request ke riwayat', () async {
    final repository = _FakeLeaveRepository();
    final container = ProviderContainer(
      overrides: [leaveRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(leaveControllerProvider.future);
    await container
        .read(leaveControllerProvider.notifier)
        .submit(
          date: DateTime.now().add(const Duration(days: 3)),
          reasonId: 'reason-1',
          amount: 2,
          description: 'Liburan keluarga',
        );

    final requests = await container.read(leaveControllerProvider.future);
    expect(requests, hasLength(1));
    expect(requests.single.status, 'pending');
    expect(requests.single.amount, 2);
  });

  test('cuti: tanggal lampau ditolak sebelum request dikirim', () async {
    final repository = _FakeLeaveRepository();
    final container = ProviderContainer(
      overrides: [leaveRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(leaveControllerProvider.future);

    await expectLater(
      container
          .read(leaveControllerProvider.notifier)
          .submit(
            date: DateTime.now().subtract(const Duration(days: 1)),
            reasonId: 'reason-1',
            amount: 1,
          ),
      throwsA(isA<ApiException>()),
    );
    expect(repository.records, isEmpty);
  });

  test(
    'lembur: submit menghasilkan request approved dan masuk riwayat',
    () async {
      final repository = _FakeOvertimeRepository();
      final container = ProviderContainer(
        overrides: [overtimeRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(overtimeControllerProvider.future);
      await container
          .read(overtimeControllerProvider.notifier)
          .submit(date: DateTime.now(), startHour: '18:00', endHour: '20:00');

      final requests = await container.read(overtimeControllerProvider.future);
      expect(requests, hasLength(1));
      expect(requests.single.status, 'approved');
      expect(requests.single.startHour, '18:00');
    },
  );

  test('lembur: jam selesai harus setelah jam mulai', () async {
    final repository = _FakeOvertimeRepository();
    final container = ProviderContainer(
      overrides: [overtimeRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(overtimeControllerProvider.future);

    await expectLater(
      container
          .read(overtimeControllerProvider.notifier)
          .submit(date: DateTime.now(), startHour: '20:00', endHour: '18:00'),
      throwsA(isA<ApiException>()),
    );
    expect(repository.records, isEmpty);
  });
}
