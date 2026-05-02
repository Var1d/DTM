class TaskModel {
  final int id;
  final int userId;
  final int? categoryId;
  final int? parentId;
  final String title;
  final String? description;
  final String status;       // todo | in_progress | done
  final String? priority;    // dihitung backend: low|medium|high|critical|overdue|none
  final DateTime? deadline;
  final DateTime? reminderAt;
  final int? progress;       // 0-100, null jika tidak ada sub-task
  final String? categoryName;
  final String? categoryColor;
  final List<TaskModel> subTasks;

  TaskModel({
    required this.id,
    required this.userId,
    this.categoryId,
    this.parentId,
    required this.title,
    this.description,
    required this.status,
    this.priority,
    this.deadline,
    this.reminderAt,
    this.progress,
    this.categoryName,
    this.categoryColor,
    this.subTasks = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id:            json['id'],
    userId:        json['user_id'],
    categoryId:    json['category_id'],
    parentId:      json['parent_id'],
    title:         json['title'],
    description:   json['description'],
    status:        json['status'] ?? 'todo',
    priority:      json['priority'],
    deadline:      json['deadline']   != null ? DateTime.parse(json['deadline']).toLocal() : null,
    reminderAt:    json['reminder_at'] != null ? DateTime.parse(json['reminder_at']).toLocal() : null,
    progress:      json['progress'],
    categoryName:  json['category_name'],
    categoryColor: json['category_color'],
    subTasks:      (json['sub_tasks'] as List<dynamic>? ?? [])
                     .map((e) => TaskModel.fromJson(e))
                     .toList(),
  );

  // Warna badge priority untuk UI
  bool get isOverdue  => priority == 'overdue';
  bool get isCritical => priority == 'critical';
  bool get isDone     => status == 'done';
}
