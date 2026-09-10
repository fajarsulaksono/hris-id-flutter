import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/request_status_chip.dart';
import '../application/leave_controller.dart';
import '../data/leave.dart';

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(leaveControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuti')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Cuti'),
      ),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorNotice(
          message: error is ApiException ? error.message : 'Gagal memuat cuti.',
          onRetry: () => ref.invalidate(leaveControllerProvider),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(leaveControllerProvider);
            await ref.read(leaveControllerProvider.future);
          },
          child: list.isEmpty
              ? const _EmptyNotice(message: 'Belum ada pengajuan cuti.')
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, index) =>
                      _LeaveTile(request: list[index]),
                ),
        ),
      ),
    );
  }

  Future<void> _showForm(BuildContext context) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _LeaveForm(),
    );
    if (submitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan cuti berhasil dikirim.')),
      );
    }
  }
}

class _LeaveForm extends ConsumerStatefulWidget {
  const _LeaveForm();

  @override
  ConsumerState<_LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends ConsumerState<_LeaveForm> {
  DateTime _date = DateTime.now();
  String? _reasonId;
  int _amount = 1;
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  late final Future<List<LeaveReason>> _reasons = ref
      .read(leaveControllerProvider.notifier)
      .reasons();

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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ajukan Cuti',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_formatDate(_date)),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<LeaveReason>>(
                future: _reasons,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      snapshot.error is ApiException
                          ? (snapshot.error! as ApiException).message
                          : 'Gagal memuat alasan cuti.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                  final reasons = snapshot.data ?? const <LeaveReason>[];
                  return DropdownButtonFormField<String>(
                    initialValue: _reasonId,
                    decoration: const InputDecoration(labelText: 'Jenis cuti'),
                    items: reasons
                        .map(
                          (reason) => DropdownMenuItem(
                            value: reason.id,
                            child: Text(reason.name),
                          ),
                        )
                        .toList(),
                    onChanged: _loading
                        ? null
                        : (value) => setState(() => _reasonId = value),
                    validator: (value) =>
                        value == null ? 'Pilih jenis cuti.' : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _amount,
                decoration: const InputDecoration(labelText: 'Jumlah hari'),
                items: List.generate(
                  31,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1} hari'),
                  ),
                ),
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _amount = value ?? 1),
              ),
              const SizedBox(height: 12),
              TextFormField(
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
      ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(leaveControllerProvider.notifier)
          .submit(
            date: _date,
            reasonId: _reasonId!,
            amount: _amount,
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

class _LeaveTile extends StatelessWidget {
  const _LeaveTile({required this.request});

  final Leave request;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event_available)),
        title: Text(
          '${_formatDate(request.leaveDate)} • ${request.amount} hari',
        ),
        subtitle: Text(request.reason?.name ?? 'Jenis cuti tidak tersedia'),
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
