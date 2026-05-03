import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  // ── Header helper ──────────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await StorageService.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Response handler ───────────────────────────────────────────────────────
  static Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Terjadi kesalahan');
  }

  static Future<bool> refreshAccessToken() async {
    final refreshToken = await StorageService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: await _headers(auth: false),
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      final body = _handle(res);
      await StorageService.saveAccessToken(body['data']['access_token']);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<http.Response> _sendWithRefresh(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) async {
    var res = await send(await _headers());
    if (res.statusCode == 401 && await refreshAccessToken()) {
      res = await send(await _headers());
    }
    return res;
  }

  // ══ AUTH ══════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _headers(auth: false),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handle(res);
  }

  static Future<void> logout(String refreshToken) async {
    await _sendWithRefresh(
      (headers) => http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers,
        body: jsonEncode({'refresh_token': refreshToken}),
      ),
    );
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await _sendWithRefresh(
      (headers) => http.get(Uri.parse('$baseUrl/auth/me'), headers: headers),
    );
    return _handle(res);
  }

  // ══ TASKS ══════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getTasks({
    String? status,
    String? priority,
    int? categoryId,
    int? courseId,
    String? date,
    String? search,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (courseId != null) params['course_id'] = courseId.toString();
    if (date != null) params['date'] = date;
    if (search != null) params['search'] = search;

    final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: params);
    final res = await _sendWithRefresh(
      (headers) => http.get(uri, headers: headers),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getTask(int id) async {
    final res = await _sendWithRefresh(
      (headers) => http.get(Uri.parse('$baseUrl/tasks/$id'), headers: headers),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> createTask(
      Map<String, dynamic> data) async {
    final res = await _sendWithRefresh(
      (headers) => http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> updateTask(
      int id, Map<String, dynamic> data) async {
    final res = await _sendWithRefresh(
      (headers) => http.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    return _handle(res);
  }

  static Future<void> updateTaskStatus(int id, String status) async {
    final res = await _sendWithRefresh(
      (headers) => http.patch(
        Uri.parse('$baseUrl/tasks/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      ),
    );
    _handle(res);
  }

  static Future<void> deleteTask(int id) async {
    final res = await _sendWithRefresh(
      (headers) =>
          http.delete(Uri.parse('$baseUrl/tasks/$id'), headers: headers),
    );
    _handle(res);
  }

  // ══ CATEGORIES ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getCategories() async {
    final res = await _sendWithRefresh(
      (headers) => http.get(Uri.parse('$baseUrl/categories'), headers: headers),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> createCategory(
      String name, String color) async {
    final res = await _sendWithRefresh(
      (headers) => http.post(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
        body: jsonEncode({'name': name, 'color': color}),
      ),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> updateCategory(
      int id, String name, String color) async {
    final res = await _sendWithRefresh(
      (headers) => http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
        body: jsonEncode({'name': name, 'color': color}),
      ),
    );
    return _handle(res);
  }

  static Future<void> deleteCategory(int id) async {
    final res = await _sendWithRefresh(
      (headers) =>
          http.delete(Uri.parse('$baseUrl/categories/$id'), headers: headers),
    );
    _handle(res);
  }

  // COURSES
  static Future<Map<String, dynamic>> getCourses() async {
    final res = await _sendWithRefresh(
      (headers) => http.get(Uri.parse('$baseUrl/courses'), headers: headers),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> createCourse(
      Map<String, dynamic> data) async {
    final res = await _sendWithRefresh(
      (headers) => http.post(
        Uri.parse('$baseUrl/courses'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> updateCourse(
      int id, Map<String, dynamic> data) async {
    final res = await _sendWithRefresh(
      (headers) => http.put(
        Uri.parse('$baseUrl/courses/$id'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    return _handle(res);
  }

  static Future<void> deleteCourse(int id) async {
    final res = await _sendWithRefresh(
      (headers) =>
          http.delete(Uri.parse('$baseUrl/courses/$id'), headers: headers),
    );
    _handle(res);
  }

  // ══ USER ══════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> updateProfile(String name) async {
    final res = await _sendWithRefresh(
      (headers) => http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
        body: jsonEncode({'name': name}),
      ),
    );
    return _handle(res);
  }

  static Future<void> updatePassword(String oldPass, String newPass) async {
    final res = await _sendWithRefresh(
      (headers) => http.put(
        Uri.parse('$baseUrl/user/password'),
        headers: headers,
        body: jsonEncode({'old_password': oldPass, 'new_password': newPass}),
      ),
    );
    _handle(res);
  }
}
