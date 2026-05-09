import 'package:flutter/material.dart';
import '../../widgets/common/loading_logo.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_helper.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/task/priority_badge.dart';
import '../../widgets/task/subtask_tile.dart';
import 'task_form_screen.dart';

/// ============================================================
/// TaskDetailScreen — Layar informasi mendalam untuk setiap tugas.
/// Menampilkan metadata tugas seperti deadline, bobot nilai,
/// deskripsi lengkap, serta pengelolaan daftar sub-tugas (subtasks).
/// ============================================================
class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  final TaskModel? task; // Data awal dari board (opsional)

  const TaskDetailScreen({super.key, required this.taskId, this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  TaskModel? _task;
  bool _loading = true;

  /// Inisialisasi data tugas. Menggunakan data awal jika tersedia untuk mempercepat render.
  @override
  void initState() {
    super.initState();
    // Gunakan data awal jika ada (instan), tidak perlu fetch ulang kecuali null
    _task = widget.task;
    _loading = _task == null;
    if (_task == null) {
      _loadTask(showLoading: true);
    }
  }

  /// Mengambil data tugas terbaru dari server API.
  Future<void> _loadTask({bool showLoading = true}) async {
    try {
      final res = await ApiService.getTask(widget.taskId);
      if (!mounted) return;
      setState(() {
        _task = TaskModel.fromJson(res['data']);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Menampilkan form modal untuk penambahan sub-tugas baru.
  Future<void> _showAddSubtaskSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SubtaskFormSheet(
        parentId: _task!.id,
        courseId: _task!.courseId,
        onSuccess: () {
          _loadTask(showLoading: false);
          // Fetch background update untuk provider utama
          context.read<TaskProvider>().fetchTasks();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _task == null) {
      return const Scaffold(body: Center(child: LoadingLogo(size: 64)));
    }
    final t = _task!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final mutedColor =
        isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.title, style: const TextStyle(fontSize: 16)),
        actions: [
          // Tombol Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TaskFormScreen(isEdit: true, task: t)));
              _loadTask();
              // Sinkronisasi provider agar board utama langsung terupdate
              if (mounted) {
                context.read<TaskProvider>().fetchTasks();
                context.read<CourseProvider>().refreshSilent();
              }
            },
          ),
          // Tombol Hapus
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: isDark ? AppTheme.dangerDark : AppTheme.dangerLight),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Tugas?'),
                  content: const Text(
                      'Apakah Anda yakin ingin menghapus tugas ini? Tindakan ini tidak dapat dibatalkan.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Hapus',
                          style: TextStyle(
                              color: isDark
                                  ? AppTheme.dangerDark
                                  : AppTheme.dangerLight)),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                final navigator = Navigator.of(context);
                await context.read<TaskProvider>().deleteTask(t.id);
                // Refresh stats matkul agar SKS Terpantau sinkron
                if (context.mounted) {
                  context.read<CourseProvider>().refreshSilent();
                }
                if (mounted) navigator.pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seksi Header: Judul dan Badge Status
            Text(t.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (t.status != 'done') PriorityBadge(priority: t.dynamicPriority),
                if (t.courseName != null)
                  _chip(
                    t.courseName!,
                    t.courseColor != null
                        ? Color(int.parse(t.courseColor!.replaceFirst('#', '0xFF')))
                        : primary,
                    Colors.white,
                  ),
                _chip(
                  taskStatusLabel(t.status, t.progress),
                  taskStatusColor(t.status, t.progress, isDark).withOpacity(0.12),
                  taskStatusColor(t.status, t.progress, isDark),
                  border: taskStatusColor(t.status, t.progress, isDark).withOpacity(0.5),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Seksi Grid Informasi Metadata Tugas
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _infoCard(
                        'Deadline', DateHelper.format(t.deadline), isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _infoCard('Smart Priority',
                        '${t.academicLabel} (${t.academicScore})', isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _infoCard('Bobot',
                        '${t.gradeWeight.toStringAsFixed(0)}%', isDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seksi Deskripsi Tugas
            if (t.description != null) ...[
              Text('Deskripsi', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(t.description!, style: TextStyle(color: mutedColor)),
              const SizedBox(height: 16),
            ],

            // Seksi Daftar Sub-tugas dan Indikator Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtask', style: Theme.of(context).textTheme.titleMedium),
                Text('${t.progress ?? 0}%',
                    style: TextStyle(color: mutedColor)),
              ],
            ),
            const SizedBox(height: 8),
            // Bar Indikator Kemajuan (Progress)
            Container(
              width: double.infinity,
              height: 7,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgSoftDark : AppTheme.bgSoftLight,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (t.progress ?? 0) / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppTheme.primaryGradientDark
                        : AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Daftar subtask atau pesan kosong
            if (t.subTasks.isEmpty)
              Text('Belum ada subtask.', style: TextStyle(color: mutedColor))
            else
              ...t.subTasks.map((s) => SubtaskTile(
                    subtask: s,
                    onStatusChanged: (status) {
                      // 1. Optimistic UI Update: Update lokal langsung biar instan
                      setState(() {
                        final idx =
                            _task!.subTasks.indexWhere((sub) => sub.id == s.id);
                        if (idx != -1) {
                          _task!.subTasks[idx] = s.copyWith(status: status);
                          // Hitung ulang progress dan status secara manual
                          final done = _task!.subTasks
                              .where((st) => st.status == 'done')
                              .length;
                          final newProgress =
                              ((done / _task!.subTasks.length) * 100).round();
                          
                          String oldStatus = _task!.status;
                          String newStatus = oldStatus;
                          if (newProgress == 100) {
                            newStatus = 'done';
                          } else if (newProgress > 0) {
                            newStatus = 'in_progress';
                          } else {
                            newStatus = 'todo';
                          }

                          _task = _task!.copyWith(
                            progress: newProgress,
                            status: newStatus,
                          );

                          // 1.5 Optimistic Update ke list utama & matkul (Tanpa refresh lambat!)
                          context.read<TaskProvider>().updateTaskLocally(_task!);
                          if (oldStatus != newStatus && (oldStatus == 'done' || newStatus == 'done')) {
                            context.read<CourseProvider>().optimisticUpdateTaskStatus(
                                _task!.courseId, newStatus == 'done');
                          }

                          // Jika status main task berubah (karena subtask diceklis semua),
                          // beri tahu server agar tidak desync!
                          if (oldStatus != newStatus) {
                            ApiService.updateTaskStatus(_task!.id, newStatus).catchError((_) {});
                          }
                        }
                      });

                      // 2. Sinkronisasi subtask ke server (background, non-blocking)
                      context.read<TaskProvider>().updateStatus(s.id, status);
                    },
                    onDelete: () async {
                      await context.read<TaskProvider>().deleteTask(s.id);
                      if (context.mounted) {
                        context.read<CourseProvider>().refreshSilent();
                      }
                      _loadTask(showLoading: false);
                    },
                  )),
            const SizedBox(height: 16),

            // Tombol tambah subtask
            CustomButton(
              label: 'Tambah Subtask',
              icon: Icons.add_task_rounded,
              onPressed: _showAddSubtaskSheet,
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu informasi kecil untuk menampilkan metadata tugas.
  Widget _infoCard(String label, String value, bool isDark) {
    final mutedColor =
        isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.2,
                  color: isDark ? Colors.white : Colors.black,
                )),
          ],
        ),
      ),
    );
  }

  /// Membangun badge/chip untuk kategori atau status tugas.
  Widget _chip(String label, Color bg, Color textColor, {Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
    );
  }

  String taskStatusLabel(String status, int? progress) {
    if (status == 'done') return 'Selesai';
    if (status == 'in_progress' || (progress ?? 0) > 0) return 'Sedang Dikerjakan';
    return 'Belum Dimulai';
  }

  Color taskStatusColor(String status, int? progress, bool isDark) {
    if (status == 'done') return Colors.green;
    if (status == 'in_progress' || (progress ?? 0) > 0) return Colors.blue;
    return isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
  }

  Widget _buildLabel(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
        ));
  }
}

/// Widget Form Subtask terpisah untuk menghindari error context leaks
class _SubtaskFormSheet extends StatefulWidget {
  final int parentId;
  final int? courseId;
  final VoidCallback onSuccess;

  const _SubtaskFormSheet({
    required this.parentId,
    this.courseId,
    required this.onSuccess,
  });

  @override
  State<_SubtaskFormSheet> createState() => _SubtaskFormSheetState();
}

class _SubtaskFormSheetState extends State<_SubtaskFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _difficulty = 'medium';
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ApiService.createTask({
        'title': title,
        'description':
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'parent_id': widget.parentId,
        'course_id': widget.courseId,
        'task_type': 'other',
        'difficulty': _difficulty,
        'status': 'todo',
      });
      if (!mounted) return;
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tambah Sub-task',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Judul Subtask',
              style: TextStyle(fontSize: 14, color: mutedColor)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(
                hintText: 'Contoh: Kerjakan bagian analisis'),
          ),
          const SizedBox(height: 12),
          Text('Kesulitan', style: TextStyle(fontSize: 14, color: mutedColor)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _difficulty,
            decoration: const InputDecoration(isDense: true),
            items: const [
              DropdownMenuItem(value: 'easy', child: Text('Mudah')),
              DropdownMenuItem(value: 'medium', child: Text('Sedang')),
              DropdownMenuItem(value: 'hard', child: Text('Sulit')),
            ],
            onChanged: (v) => setState(() => _difficulty = v ?? 'medium'),
          ),
          const SizedBox(height: 12),
          Text('Deskripsi Subtask',
              style: TextStyle(fontSize: 14, color: mutedColor)),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Batal',
                  outlined: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CustomButton(
                  label: 'Tambah Subtask',
                  isLoading: _submitting,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
