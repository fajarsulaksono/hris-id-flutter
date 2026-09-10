import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_placeholder.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Gaji',
      icon: Icons.account_balance_wallet_outlined,
    );
  }
}