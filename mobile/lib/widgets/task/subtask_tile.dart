import 'package:flutter/material.dart';
import '../../models/task_model.dart';

class SubtaskTile extends StatelessWidget {
  final TaskModel subtask;
  final ValueChanged<String> onStatusChanged;

  const SubtaskTile({super.key, required this.subtask, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      dense: true,
      value:   subtask.status == 'done',
      onChanged: (val) => onStatusChanged(val == true ? 'done' : 'todo'),
      title: Text(
        subtask.title,
        style: TextStyle(
          fontSize: 14,
          decoration: subtask.isDone ? TextDecoration.lineThrough : null,
          color: subtask.isDone ? Colors.grey : null,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
