import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

/// Status pengelolaan data tugas
enum TaskState { idle, loading, loaded, error }

/// Opsi pengurutan tugas
enum TaskSortBy { smartPriority, deadline, gradeWeight, alphabet }

/// TaskProvider — State Management untuk seluruh fungsionalitas tugas.
/// Menangani pengambilan data (fetch), filtering lokal, pencarian,
/// serta operasi CRUD tugas dengan pendekatan Optimistic UI.
///
/// OPTIMISASI PERFORMA:
/// - _applyFilters() TIDAK memanggil notifyListeners() sendiri,
///   caller bertanggung jawab untuk memanggil notifyListeners() sekali.
/// - updateStatus() dan deleteTask() TIDAK melakukan re-fetch dari server
///   setelah operasi optimistic — cukup update cache lokal.
/// - fetchTasks() menggunakan cache sinkron dari StorageService singleton.
class TaskProvider with ChangeNotifier {
  TaskState _state = TaskState.idle;
  List<TaskModel> _tasks = [];
  List<TaskModel> _filtered = [];
  String? _errorMessage;
  String _searchQuery = '';
  String? _filterStatus;
  String? _filterPriority;
  int? _filterCourseId;
  String? _filterDate;
  TaskSortBy _sortBy = TaskSortBy.smartPriority;
  bool _sortAscending = true;

  TaskState get state => _state;
  List<TaskModel> get tasks => _filtered;
  List<TaskModel> get loadedTasks => _tasks;
  String? get errorMessage => _errorMessage;
  String? get filterStatus => _filterStatus;
  String? get filterPriority => _filterPriority;
  int? get filterCourseId => _filterCourseId;
  TaskSortBy get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

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

  /// Rata-rata nilai yang didapat dari tugas yang sudah selesai
  double get averageScore {
    final scoredTasks = _tasks
        .where((t) => t.status == 'done' && t.achievedScore != null)
        .toList();
    if (scoredTasks.isEmpty) return 0;
    final total =
        scoredTasks.fold<double>(0, (sum, t) => sum + t.achievedScore!);
    return total / scoredTasks.length;
  }

  /// Total bobot nilai dari seluruh tugas
  double get totalGradeWeight {
    return _tasks.fold<double>(0, (sum, t) => sum + t.gradeWeight);
  }

  /// Bobot nilai yang sudah berhasil diselesaikan (status: done)
  double get completedGradeWeight {
    return _tasks
        .where((t) => t.status == 'done')
        .fold<double>(0, (sum, t) => sum + t.gradeWeight);
  }

  /// Filter internal — TIDAK memanggil notifyListeners().
  /// Caller bertanggung jawab memanggil notifyListeners() sendiri
  /// untuk menghindari double rebuild.
  void _applyFilters() {
    _filtered = _tasks.where((t) {
      // 1. Filter Cari
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Filter Status
      // Spesial: jika 'belum', cari yang status != 'done'
      bool matchesStatus = true;
      if (_filterStatus != null) {
        if (_filterStatus == 'not_done') {
          matchesStatus = t.status != 'done';
        } else {
          matchesStatus = t.status == _filterStatus;
        }
      }

      // 3. Filter Priority
      final matchesPriority =
          _filterPriority == null || t.priority == _filterPriority;

      // 4. Filter Matkul
      final matchesCourse =
          _filterCourseId == null || t.courseId == _filterCourseId;

      // 5. Filter Tanggal
      bool matchesDate = true;
      if (_filterDate != null && t.deadline != null) {
        final d1 = t.deadline!.toIso8601String().split('T')[0];
        matchesDate = d1 == _filterDate;
      } else if (_filterDate != null) {
        matchesDate = false;
      }

      return matchesSearch &&
          matchesStatus &&
          matchesPriority &&
          matchesCourse &&
          matchesDate;
    }).toList();

    // ── Sorting ──
    _filtered.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case TaskSortBy.smartPriority:
          // Prioritas: critical > high > medium > low > overdue > none/null
          // Urutan default: paling urgent di atas (descending score)
          cmp = _priorityWeight(b.priority) - _priorityWeight(a.priority);
          if (cmp == 0) {
            // Tie-break: deadline terdekat di atas
            cmp = _compareDeadlines(a.deadline, b.deadline);
          }
          break;
        case TaskSortBy.deadline:
          cmp = _compareDeadlines(a.deadline, b.deadline);
          break;
        case TaskSortBy.gradeWeight:
          cmp = a.gradeWeight.compareTo(b.gradeWeight);
          break;
        case TaskSortBy.alphabet:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  /// Bobot numerik untuk prioritas (semakin tinggi = semakin urgent)
  static int _priorityWeight(String? priority) => switch (priority) {
    'overdue'  => 5,
    'critical' => 4,
    'high'     => 3,
    'medium'   => 2,
    'low'      => 1,
    _          => 0,
  };

  /// Bandingkan deadline (null dianggap paling akhir)
  static int _compareDeadlines(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1; // null di bawah
    if (b == null) return -1;
    return a.compareTo(b);
  }

  /// Mengambil seluruh data tugas milik pengguna dari server
  Future<void> fetchTasks() async {
    // 1. Coba muat dari cache dulu agar UI tidak kosong (Offline-first)
    if (_tasks.isEmpty) {
      final cached = StorageService.getCachedTasks();
      if (cached != null) {
        _tasks = cached.map((e) => TaskModel.fromJson(e)).toList();
        _state = TaskState.loaded;
        _applyFilters();
        notifyListeners();
      }
    }

    // 2. Jika sudah ada data (dari cache/fetch sebelumnya), jangan set loading state
    // agar UI tidak berkedip atau menampilkan layar kosong.
    if (_tasks.isEmpty) {
      _state = TaskState.loading;
      notifyListeners();
    }

    try {
      final res = await ApiService.getTasks();
      final List data = res['data'];
      _tasks = data.map((e) => TaskModel.fromJson(e)).toList();

      // 3. Simpan data terbaru ke cache (background, non-blocking)
      StorageService.cacheTasks(data);

      _state = TaskState.loaded;
      _errorMessage = null; // Reset error jika berhasil
    } catch (e) {
      // 4. Jika gagal (misal offline), tapi kita punya data, tetap di state loaded.
      if (_tasks.isNotEmpty) {
        _state = TaskState.loaded;
        _errorMessage = "Mode Luring: Gagal menyinkronkan data terbaru.";
      } else {
        _state = TaskState.error;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    }
    _applyFilters();
    notifyListeners();
  }

  /// Melakukan pencarian tugas berdasarkan judul secara lokal
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Mengatur kriteria filter tugas (status, prioritas, mata kuliah, tanggal)
  void setFilter({String? status, String? priority, int? courseId, String? date}) {
    _filterStatus = status;
    _filterPriority = priority;
    _filterCourseId = courseId;
    _filterDate = date;
    _applyFilters();
    notifyListeners();
  }

  /// Mengatur pengurutan tugas
  void setSort(TaskSortBy sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) _sortAscending = ascending;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle arah sorting (ascending/descending)
  void toggleSortDirection() {
    _sortAscending = !_sortAscending;
    _applyFilters();
    notifyListeners();
  }

  void clearFilter() => setFilter();

  /// Membuat tugas baru dan menyinkronkannya ke server
  Future<bool> createTask(Map<String, dynamic> data) async {
    try {
      final res = await ApiService.createTask(data);
      final task = TaskModel.fromJson(res['data']);
      _tasks.insert(0, task);
      _applyFilters();
      notifyListeners();
      // Schedule notifikasi jika ada deadline (background)
      if (task.deadline != null) {
        NotificationService.scheduleTaskReminders(
          taskId: task.id,
          title: task.title,
          deadline: task.deadline!,
        ).catchError((e) {
          debugPrint('Gagal menjadwalkan notifikasi task ${task.id}: $e');
        });
      }
      // Update cache di background
      _cacheCurrentTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui data tugas yang sudah ada
  Future<bool> updateTask(int id, Map<String, dynamic> data) async {
    try {
      final res = await ApiService.updateTask(id, data);
      var task = TaskModel.fromJson(res['data']);
      
      final idx = _tasks.indexWhere((t) => t.id == id);
      if (idx != -1) {
        final old = _tasks[idx];
        // Pertahankan data join yang mungkin tidak dikembalikan oleh PUT API
        // (course_name, sub_tasks, progress, lecturer, room)
        task = task.copyWith(
          courseName: task.courseName ?? old.courseName,
          courseColor: task.courseColor ?? old.courseColor,
          subTasks: task.subTasks.isEmpty ? old.subTasks : task.subTasks,
          progress: task.progress ?? old.progress,
          lecturer: task.lecturer ?? old.lecturer,
          room: task.room ?? old.room,
        );
        _tasks[idx] = task;
      }
      _applyFilters();
      notifyListeners();
      // Update notifikasi di background
      NotificationService.cancelReminder(id).catchError((e) {
        debugPrint('Gagal membatalkan notifikasi task $id: $e');
      });
      if (task.deadline != null) {
        NotificationService.scheduleTaskReminders(
          taskId: task.id,
          title: task.title,
          deadline: task.deadline!,
        ).catchError((e) {
          debugPrint('Gagal menjadwalkan notifikasi task ${task.id}: $e');
        });
      }
      // Update cache di background
      _cacheCurrentTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui status tugas (misal: 'todo' ke 'done') dengan Optimistic UI.
  /// Optimistic update dilakukan SINKRON agar UI langsung berubah.
  /// Sinkronisasi ke server dilakukan di background tanpa blocking UI.
  void updateStatus(int id, String status) {
    // 1. Optimistic Update: UI berubah INSTAN tanpa tunggu apapun
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(status: status);
      _applyFilters();
      notifyListeners();
    }

    // 2. Sinkronisasi ke server di background (fire-and-forget)
    _syncStatusToServer(id, status);
  }

  /// Proses sinkronisasi status ke server (background, non-blocking)
  Future<void> _syncStatusToServer(int id, String status) async {
    try {
      await ApiService.updateTaskStatus(id, status);
      if (status == 'done') {
        NotificationService.cancelReminder(id).catchError((_) {});
      }
      // Update cache lokal
      _cacheCurrentTasks();
      // Background re-fetch untuk sinkronisasi data server-computed
      // (priority, academic_score, dll) tanpa blocking UI
      final res = await ApiService.getTasks();
      final List data = res['data'];
      _tasks = data.map((e) => TaskModel.fromJson(e)).toList();
      StorageService.cacheTasks(data);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      // Rollback: fetch ulang dari server jika gagal
      await fetchTasks();
    }
  }

  /// Menghapus tugas dari sistem dengan Optimistic UI.
  /// TIDAK melakukan re-fetch penuh dari server setelah berhasil.
  Future<void> deleteTask(int id) async {
    final backup = List<TaskModel>.from(_tasks);
    _tasks.removeWhere((t) => t.id == id);
    _applyFilters();
    notifyListeners();

    try {
      await ApiService.deleteTask(id);
      NotificationService.cancelReminder(id).catchError((_) {});
      // Update cache di background tanpa re-fetch
      _cacheCurrentTasks();
    } catch (e) {
      _tasks = backup;
      _applyFilters();
      notifyListeners();
      rethrow;
    }
  }

  /// Simpan state tasks saat ini ke cache lokal (background, non-blocking)
  void _cacheCurrentTasks() {
    final data = _tasks.map((t) => _taskToJson(t)).toList();
    StorageService.cacheTasks(data);
  }

  /// Konversi TaskModel ke JSON untuk caching
  Map<String, dynamic> _taskToJson(TaskModel t) {
    return {
      'id': t.id,
      'user_id': t.userId,
      'course_id': t.courseId,
      'parent_id': t.parentId,
      'title': t.title,
      'description': t.description,
      'task_type': t.taskType,
      'status': t.status,
      'priority': t.priority,
      'academic_priority': {
        'score': t.academicScore,
        'label': t.academicLabel,
      },
      'difficulty': t.difficulty,
      'grade_weight': t.gradeWeight,
      'achieved_score': t.achievedScore,
      'deadline': t.deadline?.toIso8601String(),
      'reminder_at': t.reminderAt?.toIso8601String(),
      'progress': t.progress,
      'course_name': t.courseName,
      'course_color': t.courseColor,
      'lecturer': t.lecturer,
      'room': t.room,
      'sub_tasks': t.subTasks.map((s) => _taskToJson(s)).toList(),
    };
  }
}
