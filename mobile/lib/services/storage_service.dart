import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// StorageService — Penyimpanan lokal menggunakan SharedPreferences.
/// Menggunakan singleton instance untuk menghindari overhead
/// pembuatan instance berulang (perbaikan performa kritis).
class StorageService {
  static SharedPreferences? _prefs;

  /// Inisialisasi singleton SharedPreferences.
  /// Harus dipanggil sekali di main() sebelum runApp().
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Mendapatkan instance SharedPreferences (sudah diinisialisasi).
  static SharedPreferences get _p {
    assert(_prefs != null, 'StorageService.init() belum dipanggil!');
    return _prefs!;
  }

  static Future<void> saveTokens(String access, String refresh) async {
    await _p.setString(AppConstants.keyAccessToken, access);
    await _p.setString(AppConstants.keyRefreshToken, refresh);
  }

  static String? getAccessToken() {
    return _p.getString(AppConstants.keyAccessToken);
  }

  static String? getRefreshToken() {
    return _p.getString(AppConstants.keyRefreshToken);
  }

  static Future<void> saveAccessToken(String access) async {
    await _p.setString(AppConstants.keyAccessToken, access);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _p.setString(AppConstants.keyUser, jsonEncode(user));
  }

  static Map<String, dynamic>? getUser() {
    final raw = _p.getString(AppConstants.keyUser);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  static bool hasSavedSession() {
    return _p.getString(AppConstants.keyRefreshToken) != null &&
        _p.getString(AppConstants.keyUser) != null;
  }

  // ── Caching Tugas ──
  static Future<void> cacheTasks(List<dynamic> tasks) async {
    await _p.setString('cached_tasks', jsonEncode(tasks));
  }

  static List<dynamic>? getCachedTasks() {
    final raw = _p.getString('cached_tasks');
    if (raw == null) return null;
    return jsonDecode(raw) as List;
  }

  // ── Caching Mata Kuliah ──
  static Future<void> cacheCourses(List<dynamic> courses) async {
    await _p.setString('cached_courses', jsonEncode(courses));
  }

  static List<dynamic>? getCachedCourses() {
    final raw = _p.getString('cached_courses');
    if (raw == null) return null;
    return jsonDecode(raw) as List;
  }

  static Future<void> clear() async {
    await _p.clear();
  }

  // ── Generic helpers ──
  static bool? getBool(String key) => _p.getBool(key);
  static Future<void> setBool(String key, bool value) => _p.setBool(key, value);
}
