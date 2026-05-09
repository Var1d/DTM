class AppConstants {
  // Ganti dengan IP komputer saat testing di device fisik
  static const String rootUrl = 'http://10.0.2.2:3000';
  static const String baseUrl = '$rootUrl/api';

  // SharedPreferences keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUser = 'user_data';
}
