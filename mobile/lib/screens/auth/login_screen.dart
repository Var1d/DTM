import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';
import '../tasks/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isAvailable();
    final hasSavedSession = await StorageService.hasSavedSession();
    if (!mounted) return;
    setState(() => _biometricAvailable = available && hasSavedSession);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  // Platform-specific: login pakai biometrik
  Future<void> _loginBiometric() async {
    final auth = context.read<AuthProvider>();
    final ok = await BiometricService.authenticate();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autentikasi biometrik gagal')),
        );
      }
      return;
    }
    // Jika berhasil, langsung auto-login dengan token yang tersimpan
    final logged = await auth.tryAutoLogin();
    if (logged && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Sesi tersimpan tidak ditemukan. Silakan login dengan email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Text('Selamat Datang 👋',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Masuk ke akun Anda',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey)),
                const SizedBox(height: 40),
                CustomTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (v) =>
                      v!.isEmpty ? 'Email tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (v) =>
                      v!.isEmpty ? 'Password tidak boleh kosong' : null,
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(auth.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Masuk',
                  onPressed: _login,
                  isLoading: auth.state == AuthState.loading,
                ),
                // Tombol biometrik (platform-specific feature)
                if (_biometricAvailable) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _loginBiometric,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Masuk dengan Sidik Jari'),
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Belum punya akun? '),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: Text('Daftar',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
