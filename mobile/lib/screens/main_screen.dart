import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/main_background.dart';
import 'tasks/home_screen.dart';
import 'calendar/calendar_screen.dart';
import 'courses/course_screen.dart';
import 'profile/profile_screen.dart';

/// ============================================================
/// Layar utama aplikasi — berfungsi sebagai shell global.
/// Mereplikasi MainLayout + Navbar dari versi web, diadaptasi
/// menjadi bottom navigation untuk pengalaman mobile-first.
///
/// OPTIMISASI: Menggunakan lazy-loading pages agar halaman
/// yang belum pernah dikunjungi tidak di-build, mengurangi
/// beban memori dan waktu render awal di device low-spec.
/// ============================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Track halaman yang sudah pernah dibuka (lazy-loading)
  final Set<int> _loadedPages = {0}; // Halaman pertama langsung dimuat

  // Factory builder untuk setiap halaman
  static const List<_PageBuilder> _pageBuilders = [
    _PageBuilder(builder: _buildHome),
    _PageBuilder(builder: _buildCalendar),
    _PageBuilder(builder: _buildCourse),
    _PageBuilder(builder: _buildProfile),
  ];

  static Widget _buildHome() => const HomeScreen(isMain: true);
  static Widget _buildCalendar() => const CalendarScreen(isMain: true);
  static Widget _buildCourse() => const CourseScreen(isMain: true);
  static Widget _buildProfile() => const ProfileScreen(isMain: true);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      // AppBar dengan efek glassmorphism
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            // Logo resmi dari folder assets — otomatis switch dark/light
            Image.asset(
              isDark ? 'assets/images/pio-logo.png' : 'assets/images/pio-logo-light.png',
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.task_alt, size: 28),
            ),
            const SizedBox(width: 10),
            // Sapaan singkat pengguna
            Text(
              'Halo, ${auth.user?.name ?? ''} 👋',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        // Tombol toggle tema — mereplikasi .theme-toggle dari web
        actions: [
          IconButton(
            onPressed: () => themeProvider.toggleTheme(!isDark),
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                isDark ? '☀️' : '🌙',
                key: ValueKey(isDark),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        // Efek glassmorphism pada navigasi bawah
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.bgSoftDark : AppTheme.bgSoftLight).withOpacity(0.4),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              ),
            ),
          ),
        ),
      ),
      body: MainBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: List.generate(_pageBuilders.length, (i) {
            // Lazy-load: hanya build halaman yang pernah dikunjungi
            if (!_loadedPages.contains(i)) {
              return const SizedBox.shrink();
            }
            return _pageBuilders[i].builder();
          }),
        ),
      ),
      // ── Bottom Navigation — adaptasi .nav-links dari web ──
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  /// Item navigasi bawah dengan dukungan tema gelap/terang
  Widget _buildBottomNav(bool isDark) {
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final bgColor = isDark ? AppTheme.bgSoftDark : AppTheme.bgSoftLight;

    return Container(
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.85),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.dashboard_rounded, 'Board', isDark),
              _navItem(1, Icons.calendar_month_rounded, 'Kalender', isDark),
              _navItem(2, Icons.school_rounded, 'Mata Kuliah', isDark),
              _navItem(3, Icons.person_rounded, 'Profil', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, bool isDark) {
    final selected = _currentIndex == index;
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final mutedColor = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
            _loadedPages.add(index); // Tandai halaman sudah dimuat
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Efek .nav-link.active dari web (background ungu transparan)
          color: selected ? primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? primary : mutedColor),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? textColor : mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class untuk lazy page building
class _PageBuilder {
  final Widget Function() builder;
  const _PageBuilder({required this.builder});
}
