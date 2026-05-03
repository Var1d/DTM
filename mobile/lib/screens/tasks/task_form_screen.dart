import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/course_provider.dart';
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
  final _descCtrl = TextEditingController();
  final _weightCtrl = TextEditingController(text: '0');
  final _scoreCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _deadline;
  int? _courseId;
  String _taskType = 'assignment';
  String _difficulty = 'medium';
  String _status = 'todo';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.task != null) {
      final t = widget.task!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description ?? '';
      _weightCtrl.text = t.gradeWeight.toStringAsFixed(0);
      _scoreCtrl.text = t.achievedScore?.toStringAsFixed(0) ?? '';
      _deadline = t.deadline;
      _courseId = t.courseId;
      _taskType = t.taskType;
      _difficulty = t.difficulty;
      _status = t.status;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _weightCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now()),
    );
    if (time == null) return;
    if (!mounted) return;
    setState(() => _deadline =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final data = {
      'title': _titleCtrl.text.trim(),
      'description':
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'course_id': _courseId,
      'task_type': _taskType,
      'difficulty': _difficulty,
      'grade_weight': double.tryParse(_weightCtrl.text) ?? 0,
      'achieved_score': _scoreCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_scoreCtrl.text),
      'status': _status,
      'deadline': _deadline?.toIso8601String(),
    };

    final prov = context.read<TaskProvider>();
    bool ok;
    if (widget.isEdit) {
      ok = await prov.updateTask(widget.task!.id, data);
    } else {
      ok = await prov.createTask(data);
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>().courses;
    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.isEdit ? 'Edit Tugas Akademik' : 'Tambah Tugas Akademik')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CustomTextField(
                label: 'Judul Tugas *',
                controller: _titleCtrl,
                validator: (v) =>
                    v!.isEmpty ? 'Judul tidak boleh kosong' : null),
            const SizedBox(height: 16),
            CustomTextField(
                label: 'Deskripsi (opsional)',
                controller: _descCtrl,
                maxLines: 3),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _courseId,
              hint: const Text('Pilih Mata Kuliah'),
              decoration: InputDecoration(
                labelText: 'Mata Kuliah',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Tanpa Mata Kuliah')),
                ...courses.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => _courseId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _taskType,
              decoration: InputDecoration(
                labelText: 'Jenis Tugas',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              items: const [
                DropdownMenuItem(value: 'assignment', child: Text('Tugas')),
                DropdownMenuItem(value: 'quiz', child: Text('Kuis')),
                DropdownMenuItem(value: 'mid_exam', child: Text('UTS')),
                DropdownMenuItem(value: 'final_exam', child: Text('UAS')),
                DropdownMenuItem(value: 'practicum', child: Text('Praktikum')),
                DropdownMenuItem(
                    value: 'presentation', child: Text('Presentasi')),
                DropdownMenuItem(value: 'project', child: Text('Proyek')),
                DropdownMenuItem(value: 'reading', child: Text('Bacaan')),
                DropdownMenuItem(value: 'other', child: Text('Lainnya')),
              ],
              onChanged: (v) => setState(() => _taskType = v ?? 'assignment'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _difficulty,
              decoration: InputDecoration(
                labelText: 'Tingkat Kesulitan',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('Mudah')),
                DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                DropdownMenuItem(value: 'hard', child: Text('Sulit')),
              ],
              onChanged: (v) => setState(() => _difficulty = v ?? 'medium'),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: CustomTextField(
                  label: 'Bobot Nilai (%)',
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Nilai Didapat',
                  controller: _scoreCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // Deadline picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_deadline == null
                  ? 'Pilih Deadline'
                  : DateFormat('dd MMM yyyy, HH:mm').format(_deadline!)),
              subtitle: _deadline != null
                  ? const Text('Reminder dan prioritas dihitung otomatis',
                      style: TextStyle(fontSize: 12, color: Colors.grey))
                  : null,
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_deadline != null)
                  IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _deadline = null)),
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
                ButtonSegment(value: 'todo', label: Text('Todo')),
                ButtonSegment(value: 'in_progress', label: Text('Progress')),
                ButtonSegment(value: 'done', label: Text('Selesai')),
              ],
              selected: {_status},
              onSelectionChanged: (v) => setState(() => _status = v.first),
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: widget.isEdit ? 'Simpan Perubahan' : 'Tambah Tugas',
              onPressed: _submit,
              isLoading: _submitting,
            ),
          ]),
        ),
      ),
    );
  }
}
