import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../services/api_service.dart';
import '../../utils/date_helper.dart';
import '../../widgets/task/priority_badge.dart';
import '../../widgets/task/subtask_tile.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  TaskModel? _task;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    setState(() => _loading = true);
    final res = await ApiService.getTask(widget.taskId);
    setState(() {
      _task = TaskModel.fromJson(res['data']);
      _loading = false;
    });
  }

  Future<void> _showAddSubtaskSheet() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var difficulty = 'medium';
    var submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Sub-task',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Judul Sub-task',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: difficulty,
                decoration: const InputDecoration(
                  labelText: 'Tingkat Kesulitan',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'easy', child: Text('Mudah')),
                  DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                  DropdownMenuItem(value: 'hard', child: Text('Sulit')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => difficulty = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_task_rounded),
                  label: const Text('Tambah Sub-task'),
                  onPressed: submitting
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) return;
                          final navigator = Navigator.of(ctx);
                          final taskProvider = context.read<TaskProvider>();
                          setModalState(() => submitting = true);
                          await ApiService.createTask({
                            'title': title,
                            'description': descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            'parent_id': _task!.id,
                            'course_id': _task!.courseId,
                            'task_type': 'other',
                            'difficulty': difficulty,
                            'status': 'todo',
                          });
                          if (!mounted) return;
                          navigator.pop();
                          await _loadTask();
                          if (mounted) {
                            taskProvider.fetchTasks();
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    titleCtrl.dispose();
    descCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final t = _task!;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar sesuai arsitektur yang sudah ada
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(t.title, style: const TextStyle(fontSize: 16)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                TaskFormScreen(isEdit: true, task: t)));
                    _loadTask();
                  }),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await context.read<TaskProvider>().deleteTask(t.id);
                    if (mounted) navigator.pop();
                  }),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      PriorityBadge(priority: t.priority),
                      const SizedBox(width: 8),
                      if (t.courseName != null)
                        Chip(
                            label: Text(t.courseName!,
                                style: const TextStyle(fontSize: 12)),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact),
                    ]),
                    const SizedBox(height: 16),
                    _infoRow(Icons.insights_rounded, 'Smart Priority',
                        '${t.academicLabel} (${t.academicScore})'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.percent_rounded, 'Bobot Nilai',
                        '${t.gradeWeight.toStringAsFixed(0)}%'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.fitness_center_rounded, 'Kesulitan',
                        _difficultyLabel(t.difficulty)),
                    const SizedBox(height: 16),
                    if (t.description != null) ...[
                      Text('Deskripsi',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text(t.description!),
                      const SizedBox(height: 16),
                    ],
                    if (t.deadline != null) ...[
                      _infoRow(Icons.event, 'Deadline',
                          DateHelper.format(t.deadline)),
                      const SizedBox(height: 8),
                    ],
                    if (t.reminderAt != null)
                      _infoRow(Icons.notifications_outlined, 'Reminder',
                          DateHelper.format(t.reminderAt)),
                    // Progress sub-task
                    if (t.subTasks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sub-task',
                                style: Theme.of(context).textTheme.titleSmall),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('${t.progress ?? 0}%',
                                  style: const TextStyle(color: Colors.grey)),
                              IconButton(
                                icon: const Icon(Icons.add_task_rounded),
                                tooltip: 'Tambah Sub-task',
                                onPressed: _showAddSubtaskSheet,
                              ),
                            ]),
                          ]),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (t.progress ?? 0) / 100,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      ...t.subTasks.map((s) => SubtaskTile(
                            subtask: s,
                            onStatusChanged: (status) async {
                              await context
                                  .read<TaskProvider>()
                                  .updateStatus(s.id, status);
                              _loadTask();
                            },
                          )),
                    ],
                    if (t.subTasks.isEmpty) ...[
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('Tambah Sub-task'),
                        onPressed: _showAddSubtaskSheet,
                      ),
                    ],
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value),
      ]);

  String _difficultyLabel(String value) => switch (value) {
        'easy' => 'Mudah',
        'hard' => 'Sulit',
        _ => 'Sedang',
      };
}
