import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/custom_button.dart';
import '../main_screen.dart';

/// ============================================================
/// Layar Registrasi — mereplikasi RegisterPage.jsx dari web.
/// Layout identik: auth-wrap > glass-card > logo + form.
/// ============================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Proses registrasi akun baru
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
        _nameCtrl.text.trim(), _emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Background dengan efek radial gradient seperti web
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                  .withOpacity(0.12),
              (isDark ? AppTheme.primary2Dark : AppTheme.primary2Light)
                  .withOpacity(0.08),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        // Layout .auth-wrap dari web
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GlassCard(
                  useGradient: true,
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo + judul seperti web
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                isDark
                                    ? 'assets/images/pio-logo.png'
                                    : 'assets/images/pio-logo-light.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Buat Akun PIO',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Mulai atur mata kuliah, deadline, dan target nilaimu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.textMutedDark
                                  : AppTheme.textMutedLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Field Nama Lengkap
                        _buildLabel('Nama Lengkap'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameCtrl,
                          validator: (v) =>
                              v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 14),

                        // Field Email
                        _buildLabel('Email'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v!.isEmpty ? 'Email tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 14),

                        // Field Password
                        _buildLabel('Password'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          validator: (v) => (v?.length ?? 0) < 6
                              ? 'Password minimal 6 karakter'
                              : null,
                        ),

                        // Pesan error
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(auth.errorMessage!,
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.dangerDark
                                    : AppTheme.dangerLight,
                                fontSize: 13,
                              )),
                        ],
                        const SizedBox(height: 22),

                        // Tombol Daftar
                        CustomButton(
                          label: 'Daftar',
                          onPressed: _register,
                          isLoading: auth.state == AuthState.loading,
                        ),
                        const SizedBox(height: 22),

                        // Link kembali ke login
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Sudah punya akun? '),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Masuk',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.primary2Dark
                                        : AppTheme.primary2Light,
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

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
        ));
  }
}
