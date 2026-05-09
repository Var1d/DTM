import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum CourseState { idle, loading, loaded, error }

/// CourseProvider — State Management untuk pengelolaan mata kuliah.
/// 
/// OPTIMISASI PERFORMA:
/// - createCourse() dan updateCourse() menggunakan optimistic update
///   alih-alih full re-fetch.
/// - Cache sinkron via StorageService singleton.
class CourseProvider with ChangeNotifier {
  CourseState _state = CourseState.idle;
  List<CourseModel> _courses = [];
  String? _errorMessage;

  CourseState get state => _state;
  List<CourseModel> get courses => _courses;
  String? get errorMessage => _errorMessage;

  int get totalSks => _courses.fold<int>(0, (sum, c) => sum + (c.credit));
  int get completedSks => _courses
      .where((c) => c.taskCount > 0 && c.doneCount == c.taskCount)
      .fold<int>(0, (sum, c) => sum + (c.credit));

  /// Refresh data matkul secara silent (tanpa tampilkan loading spinner)
  Future<void> refreshSilent() async {
    try {
      final res = await ApiService.getCourses();
      final List data = res['data'];
      _courses = data.map((e) => CourseModel.fromJson(e)).toList();
      StorageService.cacheCourses(data);
      notifyListeners();
    } catch (_) {
      // Gagal silent refresh — biarkan data lama
    }
  }

  Future<void> fetchCourses() async {
    // 1. Coba muat dari cache dulu (Offline-first, sinkron)
    if (_courses.isEmpty) {
      final cached = StorageService.getCachedCourses();
      if (cached != null) {
        _courses = cached.map((e) => CourseModel.fromJson(e)).toList();
        _state = CourseState.loaded;
        notifyListeners();
      }
    }

    // 2. Jika sudah ada data, jangan set loading
    if (_courses.isEmpty) {
      _state = CourseState.loading;
      notifyListeners();
    }

    try {
      final res = await ApiService.getCourses();
      final List data = res['data'];
      _courses = data.map((e) => CourseModel.fromJson(e)).toList();
      
      // 3. Simpan ke cache (background)
      StorageService.cacheCourses(data);
      
      _state = CourseState.loaded;
      _errorMessage = null;
    } catch (e) {
      // 4. Jika gagal tapi ada data lama, gunakan yang ada
      if (_courses.isNotEmpty) {
        _state = CourseState.loaded;
        _errorMessage = "Mode Luring: Gagal menyinkronkan daftar matkul.";
      } else {
        _state = CourseState.error;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    }
    notifyListeners();
  }

  /// Membuat mata kuliah baru — langsung update UI setelah API sukses
  /// tanpa full re-fetch.
  Future<void> createCourse(Map<String, dynamic> data) async {
    final res = await ApiService.createCourse(data);
    final course = CourseModel.fromJson(res['data']);
    _courses.insert(0, course);
    notifyListeners();
    // Refresh silent di background untuk sinkronisasi task count
    refreshSilent();
  }

  /// Memperbarui mata kuliah — langsung update UI lokal tanpa full re-fetch.
  Future<void> updateCourse(int id, Map<String, dynamic> data) async {
    final res = await ApiService.updateCourse(id, data);
    final updated = CourseModel.fromJson(res['data']);
    final idx = _courses.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _courses[idx] = updated;
    }
    notifyListeners();
    // Refresh silent di background untuk sinkronisasi task count
    refreshSilent();
  }

  /// Menghapus mata kuliah — optimistic delete
  Future<void> deleteCourse(int id) async {
    final backup = List<CourseModel>.from(_courses);
    _courses.removeWhere((course) => course.id == id);
    notifyListeners();
    
    try {
      await ApiService.deleteCourse(id);
    } catch (e) {
      // Rollback jika gagal
      _courses = backup;
      notifyListeners();
      rethrow;
    }
  }
}
