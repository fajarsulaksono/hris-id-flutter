class PayrollPeriod {
  const PayrollPeriod({
    required this.id,
    required this.year,
    required this.month,
    this.display,
  });

  factory PayrollPeriod.fromJson(Map<String, dynamic> json) => PayrollPeriod(
    id: json['id'] as String? ?? '',
    year: (json['year'] as num?)?.toInt() ?? 0,
    month: (json['month'] as num?)?.toInt() ?? 0,
    display: json['display'] as String?,
  );

  final String id;
  final int year;
  final int month;
  final String? display;

  String get label => display ?? '$year-${month.toString().padLeft(2, '0')}';
}

class PayrollDetail {
  const PayrollDetail({
    required this.id,
    required this.componentName,
    required this.benefitValue,
  });

  factory PayrollDetail.fromJson(Map<String, dynamic> json) => PayrollDetail(
    id: json['id'] as String? ?? '',
    componentName: json['component_name'] as String? ?? 'Komponen Gaji',
    benefitValue: _number(json['benefit_value']),
  );

  final String id;
  final String componentName;
  final num benefitValue;
}

class Payroll {
  const Payroll({
    required this.id,
    required this.employeeId,
    required this.takeHomePay,
    this.period,
    this.details = const [],
  });

  factory Payroll.fromJson(Map<String, dynamic> json) => Payroll(
    id: json['id'] as String? ?? '',
    employeeId: json['employee_id'] as String? ?? '',
    takeHomePay: _number(json['take_home_pay']),
    period: json['period'] is Map<String, dynamic>
        ? PayrollPeriod.fromJson(json['period'] as Map<String, dynamic>)
        : null,
    details:
        (json['details'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(PayrollDetail.fromJson)
            .toList() ??
        const [],
  );

  final String id;
  final String employeeId;
  final num takeHomePay;
  final PayrollPeriod? period;
  final List<PayrollDetail> details;
}

num _number(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
