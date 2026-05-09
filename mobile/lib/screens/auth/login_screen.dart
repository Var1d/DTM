import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/custom_button.dart';
import '../main_screen.dart';
import 'register_screen.dart';

/// ============================================================
/// Layar Login — mereplikasi LoginPage.jsx dari versi web.
/// Menggunakan glass-card dengan efek gradient, logo PIO,
/// dan tata letak auth-wrap yang identik.
/// ============================================================
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

  // Cek ketersediaan fitur biometrik (platform-specific)
  Future<void> _checkBiometric() async {
    final available = await BiometricService.isAvailable();
    final hasSavedSession = StorageService.hasSavedSession();
    if (!mounted) return;
    setState(() => _biometricAvailable = available && hasSavedSession);
  }

  // Login dengan email & password
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  // Login dengan biometrik (fitur platform-specific)
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
    final logged = await auth.tryAutoLogin();
    if (logged && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sesi tersimpan tidak ditemukan. Silakan login dengan email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Latar belakang dengan efek radial gradient
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withOpacity(0.12),
              (isDark ? AppTheme.primary2Dark : AppTheme.primary2Light).withOpacity(0.08),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        // Layout .auth-wrap dari web: min-height 100vh, grid place-items center
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                // Kartu login dengan efek kaca dan gradien
                child: GlassCard(
                  useGradient: true,
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo + judul PIO — logo di atas tulisan
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                isDark
                                    ? 'assets/images/pio-logo.png'
                                    : 'assets/images/pio-logo-light.png',
                                width: 80, // Ukuran diperbesar lagi untuk fokus branding
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Masuk ke PIO',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Subjudul seperti web
                        Center(
                          child: Text(
                            'Masuk untuk lanjut mengelola tugas akademikmu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Field Email
                        _buildLabel('Email'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v!.isEmpty ? 'Email tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 14),

                        // Field Password
                        _buildLabel('Password'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          validator: (v) => v!.isEmpty ? 'Password tidak boleh kosong' : null,
                        ),

                        // Pesan error
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            auth.errorMessage!,
                            style: TextStyle(
                              color: isDark ? AppTheme.dangerDark : AppTheme.dangerLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),

                        // Tombol Masuk — btn-primary gradient dari web
                        CustomButton(
                          label: 'Masuk',
                          onPressed: _login,
                          isLoading: auth.state == AuthState.loading,
                        ),

                        // Tombol biometrik (fitur platform-specific)
                        if (_biometricAvailable) ...[
                          const SizedBox(height: 12),
                          CustomButton(
                            label: 'Masuk dengan Sidik Jari',
                            icon: Icons.fingerprint,
                            outlined: true,
                            onPressed: _loginBiometric,
                          ),
                        ],
                        const SizedBox(height: 22),

                        // Link ke halaman register
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Belum punya akun? '),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const RegisterScreen())),
                                child: Text(
                                  'Daftar',
                                  style: TextStyle(
                                    color: isDark ? AppTheme.primary2Dark : AppTheme.primary2Light,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Label untuk field input
  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
      ),
    );
  }
}
