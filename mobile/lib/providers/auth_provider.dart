import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// 4 states sesuai arsitektur yang sudah ada
enum AuthState { idle, loading, authenticated, error }

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

  Future<void> logout() async {
    final refreshToken = await StorageService.getRefreshToken();
    if (refreshToken != null) await ApiService.logout(refreshToken);
    await StorageService.clear();
    _user = null;
    _setState(AuthState.idle);
  }

  void lock() {
    _user = null;
    _setState(AuthState.idle);
  }

  Future<bool> tryAutoLogin() async {
    final userData = await StorageService.getUser();
    final accessToken = await StorageService.getAccessToken();
    if (userData == null || accessToken == null) return false;

    await ApiService.refreshAccessToken();
    _user = UserModel.fromJson(userData);
    _setState(AuthState.authenticated);
    return true;
  }
}
