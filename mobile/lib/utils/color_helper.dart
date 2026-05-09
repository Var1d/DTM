import 'package:flutter/material.dart';

class ColorHelper {
  /// Menghasilkan warna yang unik dan konsisten berdasarkan teks (misal: nama matkul).
  /// Menggunakan algoritma HSL untuk memastikan warna tetap cerah dan kontras.
  static Color fromString(String text) {
    var hash = 0;
    for (var i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Gunakan hash untuk menentukan Hue (0-360)
    final double h = (hash % 360).abs().toDouble();
    
    // Saturation & Lightness dijaga agar warna tetap "Premium" dan terlihat jelas
    // S: 60-80%, L: 45-60%
    const double s = 0.7;
    const double l = 0.5;

    return HSLColor.fromAHSL(1.0, h, s, l).toColor();
  }

  /// Mengonversi objek Color ke string hex (misal: "#6366f1")
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).padLeft(6, '0')}';
  }
}
