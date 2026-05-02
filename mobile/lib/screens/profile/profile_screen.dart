import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/custom_button.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl    = TextEditingController();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl.text = user?.name ?? '';
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    await ApiService.updateProfile(_nameCtrl.text.trim());
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil diperbarui')));
  }

  Future<void> _changePassword() async {
    if (_oldPassCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) return;
    await ApiService.updatePassword(_oldPassCtrl.text, _newPassCtrl.text);
    _oldPassCtrl.clear(); _newPassCtrl.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password diperbarui')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          CircleAvatar(radius: 40, child: Text(
            (auth.user?.name.isNotEmpty == true) ? auth.user!.name[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 32))),
          const SizedBox(height: 8),
          Text(auth.user?.email ?? '', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(controller: _nameCtrl,
            decoration: InputDecoration(labelText: 'Nama',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          CustomButton(label: 'Simpan Profil', onPressed: _saveProfile, isLoading: _saving),
          const Divider(height: 40),
          const Align(alignment: Alignment.centerLeft, child: Text('Ganti Password',
            style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          TextField(controller: _oldPassCtrl, obscureText: true,
            decoration: InputDecoration(labelText: 'Password Lama',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextField(controller: _newPassCtrl, obscureText: true,
            decoration: InputDecoration(labelText: 'Password Baru',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          CustomButton(label: 'Ganti Password', onPressed: _changePassword, outlined: true),
          const Divider(height: 40),
          CustomButton(
            label: 'Keluar',
            outlined: true,
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
          ),
        ]),
      ),
    );
  }
}
