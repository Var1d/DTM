import 'package:flutter/material.dart';

/// ============================================================
/// Sistem Tema Aplikasi DTM (Daily Task Manager)
/// Diambil 1:1 dari theme.css versi desktop-web untuk menjaga
/// konsistensi branding lintas platform.
/// ============================================================
class AppTheme {
  // ── Palet Warna Light Mode (dari :root CSS) ──
  static const Color primaryLight = Color(0xFF7C3AED);
  static const Color primary2Light = Color(0xFFF97316);
  static const Color successLight = Color(0xFF22C55E);
  static const Color dangerLight = Color(0xFFEF4444);
  static const Color bgLight = Color(0xFFF1EEF9);
  static const Color bgSoftLight = Color(0xFFF8F5FD);
  static const Color bgElevatedLight = Color(0xFFFCFBFF);
  static const Color textLight =
      Color(0xFF110D26); // Near black for maximum contrast
  static const Color textMutedLight =
      Color(0xFF403952); // Much darker for readability
  static const Color borderLight = Color(0x3D5F4D8E); // rgba(95,77,142,0.24)

  // ── Palet Warna Dark Mode (dari [data-theme='dark'] CSS) ──
  static const Color primaryDark = Color(0xFFA855F7);
  static const Color primary2Dark = Color(0xFFFB923C);
  static const Color successDark = Color(0xFF4ADE80);
  static const Color dangerDark = Color(0xFFF87171);
  static const Color bgDark = Color(0xFF090913);
  static const Color bgSoftDark = Color(0xFF111120);
  static const Color bgElevatedDark = Color(0xFF151528);
  static const Color textDark = Color(0xFFF4F2FF);
  static const Color textMutedDark = Color(0xFFA9A3C8);
  static const Color borderDark = Color(0x33BDA3FF); // rgba(189,163,255,0.2)

  // ── Gradien untuk tombol utama ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary2Light],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [primaryDark, primary2Dark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Gradien untuk kartu kaca ──
  static const LinearGradient cardGlassLight = LinearGradient(
    colors: [Color(0x177C3AED), Color(0x14F97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGlassDark = LinearGradient(
    colors: [Color(0x29A855F7), Color(0x1AFB923C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Gradien untuk tombol bahaya ──
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Warna latar belakang subtil untuk efek radial gradient ──
  static const Color bgOrangeSubtle = Color(0x14F97316); // ~8% (sangat tipis)
  static const Color bgPurpleSubtle = Color(0x0F7C3AED); // ~6% (sangat tipis)

  // ── Tema Terang ──
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: primary2Light,
        surface: bgElevatedLight,
        error: dangerLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textLight,
        outline: borderLight,
      ),
      dividerColor: borderLight,
      // AppBar dengan efek glassmorphism
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textLight,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      // Tema kartu
      cardTheme: CardThemeData(
        color: bgElevatedLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
      ),
      // Tema input field
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSoftLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        labelStyle: const TextStyle(color: textMutedLight, fontSize: 14),
        hintStyle: const TextStyle(color: textMutedLight, fontSize: 14),
      ),
      // Tema tombol utama
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textLight,
          minimumSize: const Size(double.infinity, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: borderLight),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgSoftLight,
        selectedColor: primaryLight.withOpacity(0.15),
        side: const BorderSide(color: borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: textMutedLight),
        secondaryLabelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: textLight),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgElevatedLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgElevatedLight,
        contentTextStyle: const TextStyle(color: textLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textLight, fontWeight: FontWeight.w800),
        headlineMedium:
            TextStyle(color: textLight, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: textLight, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textLight, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textLight),
        bodyMedium: TextStyle(color: textMutedLight),
        labelLarge: TextStyle(color: textLight, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ── Tema Gelap ──
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: primary2Dark,
        surface: bgElevatedDark,
        error: dangerDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
        outline: borderDark,
      ),
      dividerColor: borderDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDark,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgElevatedDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSoftDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        labelStyle: const TextStyle(color: textMutedDark, fontSize: 14),
        hintStyle: const TextStyle(color: textMutedDark, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          minimumSize: const Size(double.infinity, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: borderDark),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgSoftDark,
        selectedColor: primaryDark.withOpacity(0.15),
        side: const BorderSide(color: borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgElevatedDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgElevatedDark,
        contentTextStyle: const TextStyle(color: textDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textDark, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: textDark, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textDark, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textMutedDark),
        labelLarge: TextStyle(color: textDark, fontWeight: FontWeight.w700),
      ),
    );
  }
}
