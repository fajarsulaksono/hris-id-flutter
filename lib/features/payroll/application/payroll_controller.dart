import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/payroll.dart';
import '../data/payroll_repository.dart';

final payrollRepositoryProvider = Provider<PayrollRepository>(
  (ref) => PayrollRepository(ref.watch(dioProvider)),
);

final payrollControllerProvider =
    AsyncNotifierProvider<PayrollController, List<Payroll>>(
      PayrollController.new,
    );

class PayrollController extends AsyncNotifier<List<Payroll>> {
  @override
  Future<List<Payroll>> build() => ref.read(payrollRepositoryProvider).list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(payrollRepositoryProvider).list(),
    );
  }
}
