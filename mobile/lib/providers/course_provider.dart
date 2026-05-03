import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';

enum CourseState { idle, loading, loaded, error }

class CourseProvider with ChangeNotifier {
  CourseState _state = CourseState.idle;
  List<CourseModel> _courses = [];
  String? _errorMessage;

  CourseState get state => _state;
  List<CourseModel> get courses => _courses;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCourses() async {
    _state = CourseState.loading;
    notifyListeners();
    try {
      final res = await ApiService.getCourses();
      _courses =
          (res['data'] as List).map((e) => CourseModel.fromJson(e)).toList();
      _state = CourseState.loaded;
    } catch (e) {
      _state = CourseState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> createCourse(Map<String, dynamic> data) async {
    await ApiService.createCourse(data);
    await fetchCourses();
  }

  Future<void> updateCourse(int id, Map<String, dynamic> data) async {
    await ApiService.updateCourse(id, data);
    await fetchCourses();
  }

  Future<void> deleteCourse(int id) async {
    await ApiService.deleteCourse(id);
    _courses.removeWhere((course) => course.id == id);
    notifyListeners();
  }
}
