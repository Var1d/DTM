import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

enum TaskState { idle, loading, loaded, error }

class TaskProvider with ChangeNotifier {
  TaskState _state = TaskState.idle;
  List<TaskModel> _tasks = [];
  List<TaskModel> _filtered = [];
  String? _errorMessage;
  String _searchQuery = '';
  String? _filterStatus;
  String? _filterPriority;
  int? _filterCourseId;

  TaskState get state => _state;
  List<TaskModel> get tasks => _filtered;
  List<TaskModel> get loadedTasks => _tasks;
  String? get errorMessage => _errorMessage;
  String? get filterStatus => _filterStatus;
  int? get filterCourseId => _filterCourseId;

  int get totalCount => _tasks.length;
  int get doneCount => _tasks.where((t) => t.status == 'done').length;
  int get pendingCount => _tasks.where((t) => t.status != 'done').length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;
  int get criticalCount => _tasks
      .where((t) => t.priority == 'critical' || t.priority == 'high')
      .length;
  int get todayCount => _tasks.where((t) {
        final deadline = t.deadline;
        if (deadline == null) return false;
        final now = DateTime.now();
        return deadline.year == now.year &&
            deadline.month == now.month &&
            deadline.day == now.day;
      }).length;

  double get completionRate {
    if (_tasks.isEmpty) return 0;
    return doneCount / _tasks.length;
  }

  void _setState(TaskState s, {String? err}) {
    _state = s;
    _errorMessage = err;
    notifyListeners();
  }

  // ── Fetch tasks dari API ──────────────────────────────────────────────────
  Future<void> fetchTasks({String? date}) async {
    _setState(TaskState.loading);
    try {
      final res = await ApiService.getTasks(
        status: _filterStatus,
        priority: _filterPriority,
        courseId: _filterCourseId,
        date: date,
      );
      _tasks = (res['data'] as List).map((e) => TaskModel.fromJson(e)).toList();
      _filtered = List.from(_tasks);
      _applySearch();
      _setState(TaskState.loaded);
    } catch (e) {
      _setState(TaskState.error,
          err: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Pencarian lokal (tidak hit API) ───────────────────────────────────────
  void search(String query) {
    _searchQuery = query;
    _applySearch();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filtered = List.from(_tasks);
    } else {
      _filtered = _tasks
          .where(
              (t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  // ── Filter ────────────────────────────────────────────────────────────────
  void setFilter({String? status, String? priority, int? courseId}) {
    _filterStatus = status;
    _filterPriority = priority;
    _filterCourseId = courseId;
    fetchTasks();
  }

  void clearFilter() => setFilter();

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<bool> createTask(Map<String, dynamic> data) async {
    try {
      final res = await ApiService.createTask(data);
      final task = TaskModel.fromJson(res['data']);
      _tasks.insert(0, task);
      _applySearch();
      // Schedule notifikasi jika ada deadline.
      if (task.deadline != null) {
        try {
          await NotificationService.scheduleTaskReminders(
            taskId: task.id,
            title: task.title,
            deadline: task.deadline!,
          );
        } catch (e) {
          debugPrint('Gagal menjadwalkan notifikasi task ${task.id}: $e');
        }
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(int id, Map<String, dynamic> data) async {
    try {
      final res = await ApiService.updateTask(id, data);
      final task = TaskModel.fromJson(res['data']);
      final idx = _tasks.indexWhere((t) => t.id == id);
      if (idx != -1) _tasks[idx] = task;
      _applySearch();
      // Update notifikasi
      try {
        await NotificationService.cancelReminder(id);
      } catch (e) {
        debugPrint('Gagal membatalkan notifikasi task $id: $e');
      }
      if (task.deadline != null) {
        try {
          await NotificationService.scheduleTaskReminders(
            taskId: task.id,
            title: task.title,
            deadline: task.deadline!,
          );
        } catch (e) {
          debugPrint('Gagal menjadwalkan notifikasi task ${task.id}: $e');
        }
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> updateStatus(int id, String status) async {
    await ApiService.updateTaskStatus(id, status);
    // Jika done, batalkan notifikasi
    if (status == 'done') await NotificationService.cancelReminder(id);
    await fetchTasks();
  }

  Future<void> deleteTask(int id) async {
    await ApiService.deleteTask(id);
    await NotificationService.cancelReminder(id);
    _tasks.removeWhere((t) => t.id == id);
    _applySearch();
  }
}
