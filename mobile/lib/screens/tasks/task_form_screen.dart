import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';

class TaskFormScreen extends StatefulWidget {
  final bool isEdit;
  final TaskModel? task;

  const TaskFormScreen({super.key, required this.isEdit, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  DateTime? _deadline;
  int?      _categoryId;
  String    _status    = 'todo';
  bool      _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.task != null) {
      final t = widget.task!;
      _titleCtrl.text = t.title;
      _descCtrl.text  = t.description ?? '';
      _deadline       = t.deadline;
      _categoryId     = t.categoryId;
      _status         = t.status;
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() => _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final data = {
      'title':       _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'category_id': _categoryId,
      'status':      _status,
      'deadline':    _deadline?.toIso8601String(),
    };

    final prov = context.read<TaskProvider>();
    bool ok;
    if (widget.isEdit) {
      ok = await prov.updateTask(widget.task!.id, data);
    } else {
      ok = await prov.createTask(data);
    }

    setState(() => _submitting = false);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryProvider>().categories;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Task' : 'Tambah Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CustomTextField(label: 'Judul Task *', controller: _titleCtrl,
              validator: (v) => v!.isEmpty ? 'Judul tidak boleh kosong' : null),
            const SizedBox(height: 16),
            CustomTextField(label: 'Deskripsi (opsional)', controller: _descCtrl, maxLines: 3),
            const SizedBox(height: 16),
            // Dropdown kategori
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              hint: const Text('Pilih Kategori'),
              decoration: InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tanpa Kategori')),
                ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            // Deadline picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_deadline == null
                  ? 'Pilih Deadline'
                  : DateFormat('dd MMM yyyy, HH:mm').format(_deadline!)),
              subtitle: _deadline != null
                  ? const Text('Reminder akan dihitung otomatis', style: TextStyle(fontSize: 12, color: Colors.grey))
                  : null,
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_deadline != null)
                  IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _deadline = null)),
                const Icon(Icons.chevron_right),
              ]),
              onTap: _pickDeadline,
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Status selector
            Text('Status', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'todo',        label: Text('Todo')),
                ButtonSegment(value: 'in_progress', label: Text('Progress')),
                ButtonSegment(value: 'done',        label: Text('Selesai')),
              ],
              selected: {_status},
              onSelectionChanged: (v) => setState(() => _status = v.first),
            ),
            const SizedBox(height: 32),
            CustomButton(
              label:     widget.isEdit ? 'Simpan Perubahan' : 'Tambah Task',
              onPressed: _submit,
              isLoading: _submitting,
            ),
          ]),
        ),
      ),
    );
  }
}
