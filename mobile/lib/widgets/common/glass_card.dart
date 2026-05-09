import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Widget kartu kaca (glass-card) yang mereplikasi komponen
/// `.glass-card` dari versi web. Digunakan di seluruh aplikasi
/// untuk konsistensi visual branding.
///
/// OPTIMISASI: Shadow dan border color di-cache sebagai static const
/// untuk menghindari alokasi ulang pada setiap rebuild.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool useGradient; // Mengaktifkan efek card-glass gradient
  final VoidCallback? onTap;
  final double borderRadius;

  // Pre-computed shadow (statis, tidak berubah per build)
  static const _shadowLight = BoxShadow(
    color: Color(0x144D348C), // 0.08 opacity — precalculated
    blurRadius: 16,
    offset: Offset(0, 8),
  );
  static const _shadowDark = BoxShadow(
    color: Color(0x4D000000), // 0.3 opacity — precalculated
    blurRadius: 20,
    offset: Offset(0, 8),
  );

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.useGradient = false,
    this.onTap,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final bgColor = isDark 
        ? const Color(0xD9151528) // bgElevatedDark with 0.85 opacity
        : const Color(0xD9FCFBFF); // bgElevatedLight with 0.85 opacity

    // Dekorasi kartu dengan efek kaca dan bayangan halus
    final decoration = BoxDecoration(
      color: useGradient ? null : bgColor,
      gradient: useGradient
          ? (isDark ? AppTheme.cardGlassDark : AppTheme.cardGlassLight)
          : null,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor),
      boxShadow: [isDark ? _shadowDark : _shadowLight],
    );

    final container = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }
    return container;
  }
}
