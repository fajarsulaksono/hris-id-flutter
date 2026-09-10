import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hris_id_flutter/features/payroll/application/payroll_controller.dart';
import 'package:hris_id_flutter/features/payroll/data/payroll.dart';
import 'package:hris_id_flutter/features/payroll/data/payroll_repository.dart';

class _FakePayrollRepository extends PayrollRepository {
  _FakePayrollRepository() : super(Dio(BaseOptions()));

  @override
  Future<List<Payroll>> list() async => const [
    Payroll(
      id: 'payroll-1',
      employeeId: 'employee-1',
      takeHomePay: 5000000,
      period: PayrollPeriod(id: 'period-1', year: 2026, month: 9),
      details: [
        PayrollDetail(
          id: 'detail-1',
          componentName: 'Gaji Pokok',
          benefitValue: 4500000,
        ),
        PayrollDetail(
          id: 'detail-2',
          componentName: 'Tunjangan',
          benefitValue: 500000,
        ),
      ],
    ),
  ];
}

void main() {
  test(
    'payslip: controller memuat periode dan rincian tanpa cache lokal',
    () async {
      final container = ProviderContainer(
        overrides: [
          payrollRepositoryProvider.overrideWithValue(_FakePayrollRepository()),
        ],
      );
      addTearDown(container.dispose);

      final payslips = await container.read(payrollControllerProvider.future);

      expect(payslips, hasLength(1));
      expect(payslips.single.period?.label, '2026-09');
      expect(payslips.single.takeHomePay, 5000000);
      expect(payslips.single.details, hasLength(2));
    },
  );
}
