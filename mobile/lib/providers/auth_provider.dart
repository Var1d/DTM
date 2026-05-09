import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Status autentikasi pengguna
enum AuthState { idle, loading, authenticated, error }

/// AuthProvider — Mengelola state autentikasi pengguna,
/// termasuk proses login, registrasi, logout, dan auto-login.
class AuthProvider with ChangeNotifier {
  AuthState _state = AuthState.idle;
  UserModel? _user;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuth => _state == AuthState.authenticated;

  void _setState(AuthState s, {String? err}) {
    _state = s;
    _errorMessage = err;
    notifyListeners();
  }

  /// Melakukan proses login pengguna
  Future<bool> login(String email, String password) async {
    _setState(AuthState.loading);
    try {
      final res = await ApiService.login(email, password);
      await StorageService.saveTokens(
          res['data']['access_token'], res['data']['refresh_token']);
      await StorageService.saveUser(res['data']['user']);
      _user = UserModel.fromJson(res['data']['user']);
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _setState(AuthState.error,
          err: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Melakukan proses registrasi pengguna baru
  Future<bool> register(String name, String email, String password) async {
    _setState(AuthState.loading);
    try {
      await ApiService.register(name, email, password);
      return await login(email, password);
    } catch (e) {
      _setState(AuthState.error,
          err: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Menghapus sesi pengguna dan membersihkan data lokal
  Future<void> logout() async {
    final refreshToken = StorageService.getRefreshToken();
    if (refreshToken != null) await ApiService.logout(refreshToken);
    await StorageService.clear();
    _user = null;
    _setState(AuthState.idle);
  }

  /// Mengunci aplikasi secara paksa
  void lock() {
    _user = null;
    _setState(AuthState.idle);
  }

  /// Sinkronisasi data pengguna dari server ke state lokal
  void syncUser(Map<String, dynamic> data) {
    _user = UserModel.fromJson(data);
    StorageService.saveUser(data);
    notifyListeners();
  }

  /// Memeriksa sesi yang tersimpan dan mencoba login otomatis
  Future<bool> tryAutoLogin() async {
    final userData = StorageService.getUser();
    final accessToken = StorageService.getAccessToken();
    if (userData == null || accessToken == null) return false;

    // Langsung autentikasi dari data lokal agar splash hilang instan
    _user = UserModel.fromJson(userData);
    _setState(AuthState.authenticated);

    // Verifikasi ke server di latar belakang (tanpa blocking)
    ApiService.getMe().then((res) {
      _user = UserModel.fromJson(res['data']);
      StorageService.saveUser(res['data']);
      notifyListeners();
    }).catchError((_) {
      // Tetap gunakan data lokal jika server tidak bisa dijangkau
    });

    return true;
  }
}
