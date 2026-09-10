import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/request_status_chip.dart';
import '../application/overtime_controller.dart';
import '../data/overtime.dart';

class OvertimeScreen extends ConsumerWidget {
  const OvertimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(overtimeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lembur')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Lembur'),
      ),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorNotice(
          message: error is ApiException
              ? error.message
              : 'Gagal memuat lembur.',
          onRetry: () => ref.invalidate(overtimeControllerProvider),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(overtimeControllerProvider);
            await ref.read(overtimeControllerProvider.future);
          },
          child: list.isEmpty
              ? const _EmptyNotice(message: 'Belum ada pengajuan lembur.')
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, index) =>
                      _OvertimeTile(request: list[index]),
                ),
        ),
      ),
    );
  }

  Future<void> _showForm(BuildContext context) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _OvertimeForm(),
    );
    if (submitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan lembur berhasil dikirim.')),
      );
    }
  }
}

class _OvertimeForm extends ConsumerStatefulWidget {
  const _OvertimeForm();

  @override
  ConsumerState<_OvertimeForm> createState() => _OvertimeFormState();
}

class _OvertimeFormState extends ConsumerState<_OvertimeForm> {
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);
  final _descriptionController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ajukan Lembur',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(_formatDate(_date)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _timeButton('Mulai', _start, _pickStart)),
                const SizedBox(width: 12),
                Expanded(child: _timeButton('Selesai', _end, _pickEnd)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLength: 255,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Keterangan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Kirim Pengajuan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeButton(String label, TimeOfDay value, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: _loading ? null : onPressed,
      child: Text('$label\n${value.format(context)}'),
    );
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 365)),
      initialDate: _date.isBefore(today) ? today : _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(context: context, initialTime: _end);
    if (picked != null) setState(() => _end = picked);
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(overtimeControllerProvider.notifier)
          .submit(
            date: _date,
            startHour: _formatTime(_start),
            endHour: _formatTime(_end),
            description: _descriptionController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _OvertimeTile extends StatelessWidget {
  const _OvertimeTile({required this.request});

  final Overtime request;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.schedule)),
        title: Text(_formatDate(request.overtimeDate)),
        subtitle: Text(
          '${_shortTime(request.startHour)} - ${_shortTime(request.endHour)}',
        ),
        trailing: RequestStatusChip(
          label: request.displayStatus,
          status: request.status,
        ),
      ),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 100),
          child: Center(
            child: Text(message, style: const TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _shortTime(String value) =>
    value.length >= 5 ? value.substring(0, 5) : value;
