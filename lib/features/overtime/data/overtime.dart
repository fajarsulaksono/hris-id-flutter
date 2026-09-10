class Overtime {
  const Overtime({
    required this.id,
    required this.overtimeDate,
    required this.startHour,
    required this.endHour,
    this.description,
    this.status = 'pending',
    this.statusLabel,
    this.calculatedValue,
  });

  factory Overtime.fromJson(Map<String, dynamic> json) => Overtime(
    id: json['id'] as String? ?? '',
    overtimeDate:
        DateTime.tryParse(json['overtime_date'] as String? ?? '') ??
        DateTime(1970),
    startHour: json['start_hour'] as String? ?? '',
    endHour: json['end_hour'] as String? ?? '',
    description: json['description'] as String?,
    status: json['status'] as String? ?? 'pending',
    statusLabel: json['status_label'] as String?,
    calculatedValue: (json['calculated_value'] as num?)?.toDouble(),
  );

  final String id;
  final DateTime overtimeDate;
  final String startHour;
  final String endHour;
  final String? description;
  final String status;
  final String? statusLabel;
  final double? calculatedValue;

  String get displayStatus => statusLabel ?? _statusLabels[status] ?? status;

  static const _statusLabels = {
    'pending': 'Menunggu Persetujuan',
    'approved': 'Disetujui',
    'rejected': 'Ditolak',
  };
}
