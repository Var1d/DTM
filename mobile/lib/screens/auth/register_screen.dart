import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';
import '../tasks/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            const SizedBox(height: 20),
            CustomTextField(label: 'Nama Lengkap', controller: _nameCtrl, prefixIcon: const Icon(Icons.person_outline),
              validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null),
            const SizedBox(height: 16),
            CustomTextField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: (v) => v!.isEmpty ? 'Email tidak boleh kosong' : null),
            const SizedBox(height: 16),
            CustomTextField(label: 'Password', controller: _passwordCtrl, obscureText: true,
              prefixIcon: const Icon(Icons.lock_outline),
              validator: (v) => (v?.length ?? 0) < 6 ? 'Password minimal 6 karakter' : null),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(auth.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            CustomButton(label: 'Daftar', onPressed: _register, isLoading: auth.state == AuthState.loading),
          ]),
        ),
      ),
    );
  }
}
