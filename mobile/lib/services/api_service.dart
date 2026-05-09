import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../utils/constants.dart';
import 'storage_service.dart';

/// ApiService — Layar abstraksi komunikasi antara aplikasi mobile dan backend server.
/// Menyediakan metode statis untuk operasi CRUD, autentikasi, dan pengelolaan file.
class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  /// Menghasilkan header HTTP standar dengan token otorisasi jika diperlukan.
  static Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = StorageService.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Melakukan parsing terhadap response JSON dan menangani error HTTP.
  static Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Terjadi kesalahan');
  }

  /// Mencoba memperbarui Access Token menggunakan Refresh Token.
  static Future<bool> refreshAccessToken() async {
    final refreshToken = StorageService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: _headers(auth: false),
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      final body = _handle(res);
      await StorageService.saveAccessToken(body['data']['access_token']);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Wrapper untuk pengiriman request dengan mekanisme auto-retry saat token kedaluwarsa.
  static Future<http.Response> _sendWithRefresh(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) async {
    var res = await send(_headers());
    if (res.statusCode == 401 && await refreshAccessToken()) {
      res = await send(_headers());
    }
    return res;
  }

  // ══ AUTH ══════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(auth: false),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handle(res);
  }

  static Future<void> logout(String refreshToken) async {
    try {
      await _sendWithRefresh(
        (headers) => http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: headers,
          body: jsonEncode({'refresh_token': refreshToken}),
        ),
      );
    } catch (_) {
      // Silently fail on logout
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await _sendWithRefresh(
      (headers) => http.get(Uri.parse('$baseUrl/auth/me'), headers: headers),
    );
    return _handle(res);
  }

  // ── Modul Pengelolaan Tugas (Tasks) ──
  /// Mengambil daftar tugas dengan filter opsional (status, prioritas, matkul, dsb).
  static Future<Map<String, dynamic>> getTasks({
    String? status,
    String? priority,
    int? courseId,
    String? date,
    String? search,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
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

  // ── Modul Pengelolaan Mata Kuliah (Courses) ──
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

  // ── Modul Pengelolaan Profil Pengguna (User) ──
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

  /// Mengunggah foto profil pengguna dalam format Multipart.
  static Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final token = StorageService.getAccessToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/avatar'));
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // Simulate PNG conversion by sending as avatar.png to match web behavior
    request.files.add(await http.MultipartFile.fromPath(
      'avatar', 
      filePath,
      filename: 'avatar.png',
      contentType: MediaType('image', 'png'),
    ));
    
    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);
    
    if (res.statusCode == 401 && await refreshAccessToken()) {
      // Retry once if token expired
      final newToken = StorageService.getAccessToken();
      var retryReq = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/avatar'));
      if (newToken != null) retryReq.headers['Authorization'] = 'Bearer $newToken';
      retryReq.files.add(await http.MultipartFile.fromPath(
        'avatar', 
        filePath,
        filename: 'avatar.png',
        contentType: MediaType('image', 'png'),
      ));
      final retryStream = await retryReq.send();
      final retryRes = await http.Response.fromStream(retryStream);
      return _handle(retryRes);
    }
    
    return _handle(res);
  }
}
