import 'package:flutter/material.dart';

import '../../../shared/utils/rupiah.dart';
import '../data/payroll.dart';

class PayrollDetailScreen extends StatelessWidget {
  const PayrollDetailScreen({required this.payroll, super.key});

  final Payroll payroll;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(payroll.period?.label ?? 'Detail Payslip')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Take-home pay'),
                  const SizedBox(height: 8),
                  Text(
                    rupiah(payroll.takeHomePay),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (payroll.period != null) ...[
                    const SizedBox(height: 4),
                    Text('Periode ${payroll.period!.label}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Rincian penghasilan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (payroll.details.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada rincian komponen gaji.'),
              ),
            )
          else
            ...payroll.details.map(
              (detail) => Card(
                child: ListTile(
                  title: Text(detail.componentName),
                  trailing: Text(rupiah(detail.benefitValue)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
