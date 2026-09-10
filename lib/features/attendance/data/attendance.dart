/// Model catatan absensi (hasil `AttendanceResource` backend).
class Attendance {
  const Attendance({
    required this.id,
    required this.employeeId,
    required this.attendanceDate,
    this.description,
    this.checkIn,
    this.checkOut,
    this.absent = false,
    this.lateIn = 0,
    this.lateOut = 0,
    this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'] as String? ?? '',
        employeeId: json['employee_id'] as String? ?? '',
        attendanceDate: DateTime.tryParse(json['attendance_date'] as String? ?? '') ??
            DateTime(1970),
        description: json['description'] as String?,
        checkIn: json['check_in'] as String?,
        checkOut: json['check_out'] as String?,
        absent: json['absent'] as bool? ?? false,
        lateIn: (json['late_in'] as num?)?.toInt() ?? 0,
        lateOut: (json['late_out'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] as String?,
      );

  final String id;
  final String employeeId;
  final DateTime attendanceDate;
  final String? description;
  final String? checkIn;
  final String? checkOut;
  final bool absent;
  final int lateIn;
  final int lateOut;
  final String? createdAt;

  bool get isComplete => checkIn != null && checkOut != null;
}