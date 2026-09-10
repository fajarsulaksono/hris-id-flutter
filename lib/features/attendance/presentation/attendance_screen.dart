import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../application/attendance_controller.dart';
import '../data/attendance.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(attendanceControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Absensi')),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _OfflineNotice(
          message: error is ApiException
              ? error.message
              : 'Gagal memuat data absensi.',
          onRetry: () => ref.invalidate(attendanceControllerProvider),
        ),
        data: (list) => _AttendanceView(
          records: list,
          onClockIn: () => _runAction(
            context,
            ref,
            () => ref.read(attendanceControllerProvider.notifier).clockIn(),
          ),
          onClockOut: (Attendance today) => _runAction(
            context,
            ref,
            () => ref.read(attendanceControllerProvider.notifier).clockOut(today),
          ),
        ),
      ),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on ApiException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _AttendanceView extends ConsumerWidget {
  const _AttendanceView({
    required this.records,
    required this.onClockIn,
    required this.onClockOut,
  });

  final List<Attendance> records;
  final VoidCallback onClockIn;
  final ValueChanged<Attendance> onClockOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthRecords = records
        .where((record) =>
            record.attendanceDate.year == now.year &&
            record.attendanceDate.month == now.month)
        .toList();
    Attendance? today;

    for (final record in monthRecords) {
      if (_sameDay(record.attendanceDate, now)) {
        today = record;
        break;
      }
    }

    final presentDays = monthRecords.where((record) => !record.absent).length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(attendanceControllerProvider);
        await ref.read(attendanceControllerProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _TodayCard(
            today: today,
            onClockIn: onClockIn,
            onClockOut: onClockOut,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_monthNames[now.month - 1]} ${now.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                monthRecords.isEmpty
                    ? 'Belum ada catatan'
                    : '$presentDays hari hadir',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (monthRecords.isEmpty)
            const _EmptyHistory()
          else
            ...monthRecords.map((record) => _RecordTile(record: record)),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.today,
    required this.onClockIn,
    required this.onClockOut,
  });

  final Attendance? today;
  final VoidCallback onClockIn;
  final ValueChanged<Attendance> onClockOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = _formatDate(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dateLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (today == null) ...[
              const Text('Belum ada absensi hari ini.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Absen Masuk'),
                onPressed: onClockIn,
              ),
            ] else if (!today!.isComplete) ...[
              _TimeRow(label: 'Masuk', time: today!.checkIn),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Absen Pulang'),
                onPressed: () => onClockOut(today!),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TimeRow(label: 'Masuk', time: today!.checkIn),
                  _TimeRow(label: 'Pulang', time: today!.checkOut),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: scheme.primary, size: 18),
                  const SizedBox(width: 6),
                  const Text('Absensi hari ini selesai.'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.label, required this.time});

  final String label;
  final String? time;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          _displayTime(time),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final Attendance record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            '${record.attendanceDate.day}',
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
        ),
        title: Text(_formatShortDate(record.attendanceDate)),
        subtitle: record.absent
            ? const Text('Absen', style: TextStyle(color: Colors.red))
            : Text(
                '${_displayTime(record.checkIn)} — ${_displayTime(record.checkOut)}',
              ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.event_note_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Belum ada catatan absensi.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _dayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const List<String> _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String _displayTime(String? time) {
  if (time == null || time.isEmpty) {
    return '-';
  }

  return time.length >= 5 ? time.substring(0, 5) : time;
}

String _formatDate(DateTime date) =>
    '${_dayNames[date.weekday - 1]}, ${date.day} ${_monthNames[date.month - 1]} ${date.year}';

String _formatShortDate(DateTime date) =>
    '${_dayNames[date.weekday - 1].substring(0, 3)}, ${date.day} ${_monthNames[date.month - 1].substring(0, 3)}';