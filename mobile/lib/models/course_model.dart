class CourseModel {
  final int id;
  final String name;
  final String? lecturer;
  final String? room;
  final String? day;
  final String? startTime;
  final String? endTime;
  final int credit;
  final String color;
  final int taskCount;
  final int doneCount;

  CourseModel({
    required this.id,
    required this.name,
    this.lecturer,
    this.room,
    this.day,
    this.startTime,
    this.endTime,
    required this.credit,
    required this.color,
    this.taskCount = 0,
    this.doneCount = 0,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'],
        name: json['name'],
        lecturer: json['lecturer'],
        room: json['room'],
        day: json['day'],
        startTime: json['start_time']?.toString(),
        endTime: json['end_time']?.toString(),
        credit: json['credit'] ?? 3,
        color: json['color'] ?? '#6366f1',
        taskCount: int.tryParse('${json['task_count'] ?? 0}') ?? 0,
        doneCount: int.tryParse('${json['done_count'] ?? 0}') ?? 0,
      );

  CourseModel copyWith({
    int? id,
    String? name,
    String? lecturer,
    String? room,
    String? day,
    String? startTime,
    String? endTime,
    int? credit,
    String? color,
    int? taskCount,
    int? doneCount,
  }) {
    return CourseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lecturer: lecturer ?? this.lecturer,
      room: room ?? this.room,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      credit: credit ?? this.credit,
      color: color ?? this.color,
      taskCount: taskCount ?? this.taskCount,
      doneCount: doneCount ?? this.doneCount,
    );
  }
}
