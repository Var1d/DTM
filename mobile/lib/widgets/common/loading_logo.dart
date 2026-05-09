import 'package:flutter/material.dart';

/// Widget loading kustom yang menampilkan logo PIO dengan efek pulse.
/// Menggantikan CircularProgressIndicator default untuk branding
/// yang lebih konsisten dan tampilan premium.
class LoadingLogo extends StatefulWidget {
  final double size;

  const LoadingLogo({super.key, this.size = 64});

  @override
  State<LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<LoadingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _opacity,
      child: Image.asset(
        isDark
            ? 'assets/images/pio-logo.png'
            : 'assets/images/pio-logo-light.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        // Fallback jika gambar tidak ditemukan
        errorBuilder: (_, __, ___) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
