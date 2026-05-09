import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/course_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/main_background.dart';
import '../../widgets/task/task_card.dart';
import '../tasks/task_detail_screen.dart';

/// ============================================================
/// CalendarScreen — Visualisasi Tugas berbasis Kalender.
/// Menampilkan titik (marker) pada tanggal yang memiliki tugas
/// dan daftar tugas detail saat tanggal dipilih.
/// ============================================================
class CalendarScreen extends StatefulWidget {
  final bool isMain;
  const CalendarScreen({super.key, this.isMain = false});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  /// Mendapatkan daftar tugas untuk hari tertentu, diurutkan sesuai preferensi
  List<TaskModel> _getTasksForDay(DateTime day, List<TaskModel> allTasks, TaskProvider prov) {
    final dayTasks = allTasks.where((task) {
      if (task.deadline == null) return false;
      return isSameDay(task.deadline, day);
    }).toList();

    // Terapkan sorting yang sama dengan board utama
    dayTasks.sort((a, b) {
      int cmp;
      switch (prov.sortBy) {
        case TaskSortBy.smartPriority:
          cmp = _priorityWeight(b) - _priorityWeight(a);
          if (cmp == 0) cmp = _cmpDeadline(a.deadline, b.deadline);
          break;
        case TaskSortBy.deadline:
          cmp = _cmpDeadline(a.deadline, b.deadline);
          break;
        case TaskSortBy.gradeWeight:
          cmp = a.gradeWeight.compareTo(b.gradeWeight);
          break;
        case TaskSortBy.alphabet:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
      }
      return prov.sortAscending ? cmp : -cmp;
    });
    return dayTasks;
  }

  static int _priorityWeight(TaskModel t) {
    if (t.status == 'done') return -1;
    return switch (t.priority) {
      'overdue'  => 5, 'critical' => 4, 'high' => 3,
      'medium'   => 2, 'low'      => 1, _      => 0,
    };
  }
  static int _cmpDeadline(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final mutedColor = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    final titleColor = isDark ? AppTheme.textDark : AppTheme.textLight;

    final tasksForSelectedDay = _getTasksForDay(_selectedDay!, taskProv.loadedTasks, taskProv);

    String sortLabel = switch (taskProv.sortBy) {
      TaskSortBy.smartPriority => 'Prioritas',
      TaskSortBy.deadline => 'Deadline',
      TaskSortBy.gradeWeight => 'Bobot',
      TaskSortBy.alphabet => 'A-Z',
    };

    return MainBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.isMain 
          ? null 
          : AppBar(backgroundColor: Colors.transparent, title: const Text('Kalender Tugas')),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Section ──
            if (widget.isMain)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kalender Akademik',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Pantau tenggat waktu tugasmu secara visual.',
                      style: TextStyle(color: mutedColor, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // ── Calendar Widget in GlassCard ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TableCalendar<TaskModel>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  // Mengunci tampilan ke Bulan saja sesuai permintaan
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) =>
                      _getTasksForDay(day, taskProv.loadedTasks, taskProv),

                  // Styling Kalender agar sesuai tema PIO
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: primary, width: 1),
                    ),
                    selectedDecoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle:
                        TextStyle(color: primary, fontWeight: FontWeight.bold),
                    defaultTextStyle: TextStyle(color: titleColor),
                    weekendTextStyle: const TextStyle(color: Colors.redAccent),
                    outsideTextStyle:
                        TextStyle(color: mutedColor.withOpacity(0.5)),
                    // Sembunyikan marker bawaan karena kita pakai builder kustom
                    markersMaxCount: 0,
                  ),

                  // Custom Marker Builder: Menampilkan titik sesuai jumlah tugas
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;

                      // Menampilkan hingga 4 titik tugas
                      return Positioned(
                        bottom: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: events.take(4).map((task) {
                            final isDone = task.status == 'done';
                            return Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? Colors.green
                                    : (isDark
                                        ? AppTheme.primary2Dark
                                        : AppTheme.primary2Light),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                  headerStyle: HeaderStyle(
                    formatButtonVisible: false, // Hapus filter format sesuai permintaan
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: primary),
                    rightChevronIcon: Icon(Icons.chevron_right, color: primary),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: mutedColor, fontSize: 12),
                    weekendStyle:
                        const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ),
            ),

            // ── Header + Sort toggle ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tasksForSelectedDay.isEmpty
                        ? 'Tidak ada tugas'
                        : '${tasksForSelectedDay.length} tugas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: mutedColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => taskProv.toggleSortDirection(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort_rounded, size: 12, color: primary),
                          const SizedBox(width: 4),
                          Text(sortLabel, style: TextStyle(fontSize: 10, color: mutedColor, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 2),
                          Icon(
                            taskProv.sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 10, color: primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Task List for Selected Day ──
            Expanded(
              child: tasksForSelectedDay.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_rounded, 
                            size: 48, color: mutedColor.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text('Tidak ada tugas di hari ini',
                              style: TextStyle(color: mutedColor)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: tasksForSelectedDay.length,
                      itemBuilder: (context, index) {
                        final task = tasksForSelectedDay[index];
                        return TaskCard(
                          task: task,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(taskId: task.id, task: task),
                              ),
                            );
                            // Sinkronisasi setelah kembali dari detail
                            if (context.mounted) {
                              context.read<TaskProvider>().fetchTasks();
                              context.read<CourseProvider>().refreshSilent();
                            }
                          },
                          onStatusChanged: (status) {
                            taskProv.updateStatus(task.id, status);
                            context.read<CourseProvider>().optimisticUpdateTaskStatus(
                                task.courseId, status == 'done');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
