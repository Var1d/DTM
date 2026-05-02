import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../utils/date_helper.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final ValueChanged<String> onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == 'done';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.isOverdue
              ? Colors.red.withOpacity(0.4)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Checkbox status
                  GestureDetector(
                    onTap: () => onStatusChanged(isDone ? 'todo' : 'done'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape:       BoxShape.circle,
                        color:       isDone ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        border:      Border.all(
                          color: isDone
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
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
                        fontWeight: FontWeight.w600,
                        fontSize:   15,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color:      isDone ? Colors.grey : null,
                      ),
                    ),
                  ),
                  PriorityBadge(priority: task.priority),
                ],
              ),
              if (task.deadline != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const SizedBox(width: 32),
                  Icon(Icons.access_time_rounded, size: 13, color: task.isOverdue ? Colors.red : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateHelper.timeAgo(task.deadline),
                    style: TextStyle(fontSize: 12, color: task.isOverdue ? Colors.red : Colors.grey),
                  ),
                ]),
              ],
              // Progress bar sub-task
              if (task.subTasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(children: [
                  const SizedBox(width: 32),
                  Expanded(child: LinearProgressIndicator(
                    value:            (task.progress ?? 0) / 100,
                    borderRadius:     BorderRadius.circular(4),
                    backgroundColor:  Colors.grey.shade200,
                    minHeight:        5,
                  )),
                  const SizedBox(width: 8),
                  Text('${task.progress ?? 0}%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
              ],
              // Kategori label
              if (task.categoryName != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const SizedBox(width: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color:        Color(int.parse('0xFF${task.categoryColor!.replaceAll('#', '')}')).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(task.categoryName!, style: const TextStyle(fontSize: 11)),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
