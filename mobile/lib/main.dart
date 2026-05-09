import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/course_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'widgets/common/loading_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi storage singleton SEBELUM semua service lainnya
  await StorageService.init();
  // Init notifikasi di background agar tidak blocking launch
  NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'PIO',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

// Cek apakah user sudah login atau belum
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();
    if (!mounted) return;
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF090913) // AppTheme.bgDark
            : const Color(0xFFF1EEF9), // AppTheme.bgLight
        body: const Center(
          child: LoadingLogo(size: 100),
        ),
      );
    }
    final auth = context.watch<AuthProvider>();
    return auth.isAuth ? const MainScreen() : const LoginScreen();
  }
}
