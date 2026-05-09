import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Provider untuk mengelola tema aplikasi (Light/Dark mode)
/// Menggunakan singleton StorageService untuk penyimpanan yang efisien.
/// UI diperbarui instan, penyimpanan di background tanpa blocking.
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  static const String _autoKey = 'is_dark_mode_auto';
  bool _isDarkMode = false;
  bool _useSystemTheme = true;

  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  /// Mengatur tema berdasarkan preferensi pengguna
  ThemeMode get themeMode {
    if (_useSystemTheme) return ThemeMode.system;
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggle antara mode gelap dan terang secara manual.
  /// UI langsung di-update, penyimpanan di background.
  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    _useSystemTheme = false;
    notifyListeners();
    // Simpan di background tanpa blocking UI
    StorageService.setBool(_themeKey, _isDarkMode);
    StorageService.setBool(_autoKey, false);
  }

  /// Mengatur untuk mengikuti tema sistem
  void setUseSystemTheme(bool useSystem) {
    _useSystemTheme = useSystem;
    notifyListeners();
    StorageService.setBool(_autoKey, _useSystemTheme);
  }

  /// Memuat pengaturan tema dari penyimpanan lokal (sinkron via singleton)
  void _loadThemeFromPrefs() {
    _isDarkMode = StorageService.getBool(_themeKey) ?? false;
    _useSystemTheme = StorageService.getBool(_autoKey) ?? true;
    notifyListeners();
  }
}
