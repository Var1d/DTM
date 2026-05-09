import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'loading_logo.dart';

/// Tombol dengan efek gradien yang mereplikasi .btn-primary, .btn-outline,
/// dan .btn-danger dari versi web.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined; // Menggunakan gaya .btn-outline
  final bool danger;   // Menggunakan gaya .btn-danger
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.danger = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Konten tombol (loading spinner atau teks + ikon)
    final child = isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: LoadingLogo(size: 24),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          );

    // Gaya .btn-outline
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      );
    }

    // Gaya .btn-danger (gradien merah-oranye)
    if (danger) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.dangerGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: child,
          ),
        ),
      );
    }

    // Gaya .btn-primary (gradien ungu-oranye) — default
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.primaryGradientDark : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: child,
        ),
      ),
    );
  }
}
