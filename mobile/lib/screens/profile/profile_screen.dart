import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/custom_button.dart';
import '../auth/login_screen.dart';

/// ============================================================
/// ProfileScreen — Halaman pengaturan akun dan profil pengguna.
/// Menyediakan fitur pembaruan informasi profil, penggantian
/// kata sandi, unggah foto profil dengan fitur pemotongan (crop),
/// serta fitur keamanan penguncian aplikasi.
/// ============================================================
class ProfileScreen extends StatefulWidget {
  final bool isMain;
  const ProfileScreen({super.key, this.isMain = false});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _saving = false;
  String? _msg;
  final ImagePicker _picker = ImagePicker();

  /// Inisialisasi data pengguna saat halaman dibuka untuk ditampilkan di form
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl.text = user?.name ?? '';
  }
  Future<void> _showPickOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Foto Profil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickBtn(
                    Icons.camera_alt_rounded, 'Kamera', ImageSource.camera),
                _buildPickBtn(
                    Icons.photo_library_rounded, 'Galeri', ImageSource.gallery),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickBtn(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _pickAvatar(source);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Proses pengambilan foto profil dan sinkronisasi ke server
  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
      );
      if (image == null) return;

      // Masuk ke tahap Crop Manual (seperti web)
      final croppedFile = await _cropImage(image.path);
      if (croppedFile == null) return;

      setState(() {
        _saving = true;
        _msg = null;
      });

      final res = await ApiService.uploadAvatar(croppedFile.path);
      if (mounted) {
        context.read<AuthProvider>().syncUser(res['data']);
        setState(() {
          _msg = 'Foto profil berhasil diperbarui';
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _msg = 'Gagal upload: ${e.toString().replaceAll('Exception: ', '')}';
          _saving = false;
        });
      }
    }
  }

  /// Fungsi untuk melakukan pemotongan gambar secara manual
  /// Mendukung konfigurasi UI Android dan iOS yang disesuaikan dengan tema aplikasi.
  Future<CroppedFile?> _cropImage(String path) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final bg = isDark ? AppTheme.bgDark : AppTheme.bgLight;
    // Warna teks toolbar disesuaikan dengan tema: putih di gelap, hitam di terang
    final toolbarTextColor = isDark ? Colors.white : Colors.black;

    return await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Foto Profil',
          toolbarColor: bg,
          toolbarWidgetColor: toolbarTextColor,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          activeControlsWidgetColor: primary,
          backgroundColor: bg,
          cropStyle: CropStyle.circle,
          showCropGrid: false,
          cropFrameColor: Colors.transparent,
          cropFrameStrokeWidth: 0,
        ),
        IOSUiSettings(
          title: 'Crop Foto Profil',
          aspectRatioLockEnabled: true,
          cropStyle: CropStyle.circle,
        ),
      ],
    );
  }

  /// Menyimpan perubahan data nama profil ke server
  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.updateProfile(_nameCtrl.text.trim());
      if (mounted) {
        context.read<AuthProvider>().syncUser(res['data']);
        setState(() {
          _msg = 'Profil berhasil diperbarui';
        });
      }
    } catch (e) {
      setState(() => _msg = 'Gagal memperbarui profil');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Melakukan pembaruan kata sandi pengguna
  Future<void> _changePassword() async {
    if (_oldPassCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiService.updatePassword(_oldPassCtrl.text, _newPassCtrl.text);
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
      setState(() => _msg = 'Password berhasil diperbarui');
    } catch (e) {
      setState(() => _msg = 'Gagal mengganti password');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.isMain
          ? null
          : AppBar(
              backgroundColor: Colors.transparent, title: const Text('Profil')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AuthProvider>().tryAutoLogin(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul halaman
              Text('Profil Saya',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              // Kartu informasi profil pengguna
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar foto atau inisial nama
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isDark
                            ? AppTheme.primaryGradientDark
                            : AppTheme.primaryGradient,
                        image: auth.user?.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(auth.user!.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: auth.user?.avatarUrl == null
                          ? Center(
                              child: Text(
                                (auth.user?.name.isNotEmpty == true)
                                    ? auth.user!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    // Info nama, email, dan aksi ganti foto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.user?.name ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.user?.email ?? '',
                            style: TextStyle(color: mutedColor, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _saving ? null : _showPickOptions,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: primary),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _saving ? 'Mengunggah...' : 'Ganti Foto',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Notifikasi feedback aksi pengguna
              if (_msg != null) ...[
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: primary),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_msg!,
                              style: const TextStyle(fontSize: 13))),
                      GestureDetector(
                        onTap: () => setState(() => _msg = null),
                        child: Icon(Icons.close, size: 16, color: mutedColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Seksi Edit Profil
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Profil',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 14),
                    _buildLabel('Nama'),
                    const SizedBox(height: 6),
                    TextField(controller: _nameCtrl),
                    const SizedBox(height: 14),
                    CustomButton(
                      label: 'Simpan Profil',
                      onPressed: _saveProfile,
                      isLoading: _saving,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Seksi Ganti Password
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ganti Password',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 14),
                    _buildLabel('Password Lama'),
                    const SizedBox(height: 6),
                    TextField(controller: _oldPassCtrl, obscureText: true),
                    const SizedBox(height: 12),
                    _buildLabel('Password Baru'),
                    const SizedBox(height: 6),
                    TextField(controller: _newPassCtrl, obscureText: true),
                    const SizedBox(height: 14),
                    CustomButton(
                      label: 'Ganti Password',
                      outlined: true,
                      onPressed: _changePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Kunci sementara sesi tanpa logout
              CustomButton(
                label: 'Kunci Aplikasi',
                outlined: true,
                icon: Icons.lock_outline,
                onPressed: () {
                  auth.lock();
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false);
                },
              ),
              const SizedBox(height: 12),

              // Keluar dari akun sepenuhnya
              CustomButton(
                label: 'Keluar dari Akun',
                danger: true,
                icon: Icons.logout_rounded,
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await auth.logout();
                  if (mounted) {
                    navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false);
                  }
                },
              ),
            ],
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
