import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _auth = LocalAuthentication();

  // Cek apakah perangkat mendukung biometrik
  static Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  // Lakukan autentikasi biometrik
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Masuk menggunakan sidik jari atau Face ID',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
