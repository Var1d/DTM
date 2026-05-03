class TaskModel {
  final int id;
  final int userId;
  final int? courseId;
  final int? parentId;
  final String title;
  final String? description;
  final String taskType;
  final String status; // todo | in_progress | done
  final String?
      priority; // dihitung backend: low|medium|high|critical|overdue|none
  final int academicScore;
  final String academicLabel;
  final String difficulty;
  final double gradeWeight;
  final double? achievedScore;
  final DateTime? deadline;
  final DateTime? reminderAt;
  final int? progress; // 0-100, null jika tidak ada sub-task
  final String? courseName;
  final String? courseColor;
  final String? lecturer;
  final String? room;
  final List<TaskModel> subTasks;

  TaskModel({
    required this.id,
    required this.userId,
    this.courseId,
    this.parentId,
    required this.title,
    this.description,
    this.taskType = 'assignment',
    required this.status,
    this.priority,
    this.academicScore = 0,
    this.academicLabel = 'Aman',
    this.difficulty = 'medium',
    this.gradeWeight = 0,
    this.achievedScore,
    this.deadline,
    this.reminderAt,
    this.progress,
    this.courseName,
    this.courseColor,
    this.lecturer,
    this.room,
    this.subTasks = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'],
        userId: json['user_id'],
        courseId: json['course_id'],
        parentId: json['parent_id'],
        title: json['title'],
        description: json['description'],
        taskType: json['task_type'] ?? 'assignment',
        status: json['status'] ?? 'todo',
        priority: json['priority'],
        academicScore: json['academic_priority']?['score'] ?? 0,
        academicLabel: json['academic_priority']?['label'] ?? 'Aman',
        difficulty: json['difficulty'] ?? 'medium',
        gradeWeight: double.tryParse('${json['grade_weight'] ?? 0}') ?? 0,
        achievedScore: json['achieved_score'] == null
            ? null
            : double.tryParse('${json['achieved_score']}'),
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline']).toLocal()
            : null,
        reminderAt: json['reminder_at'] != null
            ? DateTime.parse(json['reminder_at']).toLocal()
            : null,
        progress: json['progress'],
        courseName: json['course_name'],
        courseColor: json['course_color'],
        lecturer: json['lecturer'],
        room: json['room'],
        subTasks: (json['sub_tasks'] as List<dynamic>? ?? [])
            .map((e) => TaskModel.fromJson(e))
            .toList(),
      );

  // Warna badge priority untuk UI
  bool get isOverdue => priority == 'overdue';
  bool get isCritical => priority == 'critical';
  bool get isDone => status == 'done';
}
