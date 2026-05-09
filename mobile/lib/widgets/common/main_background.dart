import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Wrapper untuk menambahkan gradien latar belakang oranye tipis di pojok kiri atas,
/// sesuai dengan estetika radial-gradient pada versi web.
///
/// OPTIMISASI: Menggunakan ukuran gradient lebih kecil dan Opacity widget
/// yang lebih ringan dibanding Container besar dengan RadialGradient.
/// Dibungkus RepaintBoundary agar tidak ikut repaint saat konten berubah.
class MainBackground extends StatelessWidget {
  final Widget child;

  const MainBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Latar belakang solid dasar
        Container(color: Theme.of(context).scaffoldBackgroundColor),
        
        // Gradien dekoratif — cached dan dibungkus RepaintBoundary
        const RepaintBoundary(
          child: _GradientOverlay(),
        ),

        // Konten utama
        child,
      ],
    );
  }
}

/// Widget statis untuk overlay gradien. Dibuat terpisah agar bisa
/// di-const dan tidak rebuild saat parent berubah.
class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradien oranye tipis di kiri atas (ukuran dikurangi untuk performa)
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.bgOrangeSubtle,
                  Color(0x00F97316), // transparent orange
                ],
              ),
            ),
          ),
        ),

        // Gradien ungu tipis di kanan atas (ukuran dikurangi untuk performa)
        Positioned(
          top: -80,
          right: -120,
          child: Container(
            width: 400,
            height: 400,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.bgPurpleSubtle,
                  Color(0x007C3AED), // transparent purple
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
