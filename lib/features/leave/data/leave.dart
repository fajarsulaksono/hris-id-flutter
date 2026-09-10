class LeaveReason {
  const LeaveReason({required this.id, required this.name, this.code});

  factory LeaveReason.fromJson(Map<String, dynamic> json) => LeaveReason(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    code: json['code'] as String?,
  );

  final String id;
  final String name;
  final String? code;
}

class Leave {
  const Leave({
    required this.id,
    required this.leaveDate,
    required this.reasonId,
    required this.amount,
    this.reason,
    this.description,
    this.status = 'pending',
    this.statusLabel,
    this.approvedById,
  });

  factory Leave.fromJson(Map<String, dynamic> json) => Leave(
    id: json['id'] as String? ?? '',
    leaveDate:
        DateTime.tryParse(json['leave_date'] as String? ?? '') ??
        DateTime(1970),
    reasonId: json['reason_id'] as String? ?? '',
    amount: (json['amount'] as num?)?.toInt() ?? 1,
    reason: json['reason'] is Map<String, dynamic>
        ? LeaveReason.fromJson(json['reason'] as Map<String, dynamic>)
        : null,
    description: json['description'] as String?,
    status: json['status'] as String? ?? 'pending',
    statusLabel: json['status_label'] as String?,
    approvedById: json['approved_by_id'] as String?,
  );

  final String id;
  final DateTime leaveDate;
  final String reasonId;
  final int amount;
  final LeaveReason? reason;
  final String? description;
  final String status;
  final String? statusLabel;
  final String? approvedById;

  String get displayStatus => statusLabel ?? _statusLabels[status] ?? status;

  static const _statusLabels = {
    'pending': 'Menunggu Persetujuan',
    'approved': 'Disetujui',
    'rejected': 'Ditolak',
  };
}
