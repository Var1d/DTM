import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_helper.dart';
import 'priority_badge.dart';

/// ============================================================
/// Kartu tugas — mereplikasi DraggableTaskCard dari BoardPage.jsx.
/// Menggunakan styling .task-card dari theme.css:
///   - bg-elevated, border, border-radius 12px
///   - Hover translateY(-2px)
///   - Badge kursus berwarna, badge kesulitan, progress bar
///
/// OPTIMISASI: Shadow pre-computed sebagai static const,
/// dibungkus RepaintBoundary agar tidak ikut repaint saat
/// list di-scroll.
/// ============================================================
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final ValueChanged<String> onStatusChanged;

  // Pre-computed shadows (statis, tidak berubah per build)
  static const _shadowLight = BoxShadow(
    color: Color(0x0F4D348C), // 0.06 opacity
    blurRadius: 10,
    offset: Offset(0, 4),
  );
  static const _shadowDark = BoxShadow(
    color: Color(0x33000000), // 0.2 opacity
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = task.status == 'done';
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final bgColor = isDark ? AppTheme.bgElevatedDark : AppTheme.bgElevatedLight;
    final mutedColor = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Mengikuti .task-card dari web
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: task.isOverdue
                  ? (isDark ? const Color(0x80F87171) : const Color(0x80EF4444))
                  : borderColor,
            ),
            boxShadow: [isDark ? _shadowDark : _shadowLight],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Baris atas: checkbox + judul + prioritas ──
              Row(
                children: [
                  // Checkbox status (toggle done/todo)
                  GestureDetector(
                    onTap: () => onStatusChanged(isDone ? 'todo' : 'done'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? primary : Colors.transparent,
                        border: Border.all(
                          color: isDone ? primary : mutedColor,
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? mutedColor : null,
                      ),
                    ),
                  ),
                  PriorityBadge(priority: task.priority),
                ],
              ),
              const SizedBox(height: 10),

              // Badge mata kuliah, status, kesulitan, tipe, dan bobot nilai
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (task.courseName != null)
                    _WebBadge(
                      label: task.courseName!,
                      bgColor: task.courseColor != null
                          ? Color(int.parse(task.courseColor!.replaceFirst('#', '0xFF')))
                          : primary,
                      textColor: Colors.white,
                    ),
                  if (task.status != 'done') // Sembunyikan jika sudah selesai
                    _WebBadge(
                      label: (task.status == 'in_progress' || (task.progress ?? 0) > 0) 
                          ? 'Sedang Dikerjakan' 
                          : 'Belum Dimulai',
                      bgColor: (task.status == 'in_progress' || (task.progress ?? 0) > 0)
                          ? const Color(0x1F2196F3) // blue 0.12 opacity
                          : Colors.transparent,
                      textColor: (task.status == 'in_progress' || (task.progress ?? 0) > 0) 
                          ? Colors.blue 
                          : mutedColor,
                      borderColor: (task.status == 'in_progress' || (task.progress ?? 0) > 0) 
                          ? const Color(0x802196F3) // blue 0.5 opacity
                          : borderColor,
                    ),
                  _WebBadge(
                    label: _difficultyLabel(task.difficulty),
                    bgColor: Colors.transparent,
                    textColor: mutedColor,
                    borderColor: borderColor,
                  ),
                  _WebBadge(
                    label: _taskTypeLabel(task.taskType),
                    bgColor: Colors.transparent,
                    textColor: mutedColor,
                    borderColor: borderColor,
                  ),
                  _WebBadge(
                    label: 'Bobot ${task.gradeWeight.toStringAsFixed(0)}%',
                    bgColor: Colors.transparent,
                    textColor: mutedColor,
                    borderColor: borderColor,
                  ),
                ],
              ),

              // Informasi deadline
              if (task.deadline != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Deadline ${DateHelper.timeAgo(task.deadline)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: task.isOverdue
                        ? (isDark ? AppTheme.dangerDark : AppTheme.dangerLight)
                        : mutedColor,
                  ),
                ),
              ],

              // Progress bar sub-task
              if (task.subTasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${task.subTasks.length} subtask',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    Text(
                      '${task.progress ?? 0}%',
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Progress bar penyelesaian subtask
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgSoftDark : AppTheme.bgSoftLight,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: borderColor),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (task.progress ?? 0) / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],

              // Skor dan label Smart Priority
              if (task.academicScore > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Skor ${task.academicScore} - ${task.academicLabel}',
                  style: TextStyle(fontSize: 11, color: mutedColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Label tipe tugas
  static String _taskTypeLabel(String type) => switch (type) {
        'quiz' => 'Kuis',
        'mid_exam' => 'UTS',
        'final_exam' => 'UAS',
        'practicum' => 'Praktikum',
        'presentation' => 'Presentasi',
        'project' => 'Proyek',
        'reading' => 'Bacaan',
        'other' => 'Lainnya',
        _ => 'Tugas',
      };

  static String _difficultyLabel(String d) => switch (d) {
        'easy' => 'Mudah',
        'hard' => 'Sulit',
        _ => 'Sedang',
      };
}

/// Badge label kecil untuk informasi tambahan pada kartu tugas
class _WebBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;

  const _WebBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500),
      ),
    );
  }
}
