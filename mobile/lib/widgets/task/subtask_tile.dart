import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../utils/app_theme.dart';
import '../common/glass_card.dart';

/// ============================================================
/// Tile untuk menampilkan dan mengelola subtask dalam daftar tugas.
/// Menggunakan glass-card dengan checkbox, judul (strikethrough
/// jika done), dan badge kesulitan.
/// ============================================================
class SubtaskTile extends StatelessWidget {
  final TaskModel subtask;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDelete;

  const SubtaskTile({
    super.key,
    required this.subtask,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = subtask.status == 'done';
    final mutedColor = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () => onStatusChanged(isDone ? 'todo' : 'done'),
        child: Row(
          children: [
            // Checkbox status subtask
            Checkbox(
              value: isDone,
              onChanged: (val) => onStatusChanged(val == true ? 'done' : 'todo'),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            // Judul subtask — strikethrough jika selesai
            Expanded(
              child: Text(
                subtask.title,
                style: TextStyle(
                  fontSize: 14,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? mutedColor : textColor,
                ),
              ),
            ),
            // Badge tingkat kesulitan subtask
            Text(
              _difficultyLabel(subtask.difficulty),
              style: TextStyle(fontSize: 12, color: mutedColor),
            ),
            const SizedBox(width: 4),
            // Tombol Hapus
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: isDark ? AppTheme.dangerDark : AppTheme.dangerLight,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  static String _difficultyLabel(String d) => switch (d) {
        'easy' => 'Mudah',
        'hard' => 'Sulit',
        _ => 'Sedang',
      };
}
