import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  final String? priority;
  const PriorityBadge({super.key, this.priority});

  @override
  Widget build(BuildContext context) {
    final cfg = _config(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cfg.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        cfg.$3,
        style: TextStyle(
          fontSize: 11,
          color: cfg.$2,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  // Konfigurasi warna dan label untuk setiap tingkat prioritas
  static (Color, Color, String) _config(String? p) => switch (p) {
        'overdue' => (
            const Color(0xFFFEE2E2),
            const Color(0xFFDC2626),
            'Terlambat'
          ),
        'critical' => (
            const Color(0xFFFFEDD5),
            const Color(0xFFEA580C),
            'Kritis'
          ),
        'high' => (const Color(0xFFFEF3C7), const Color(0xFFD97706), 'Tinggi'),
        'medium' => (
            const Color(0xFFFEFCE8),
            const Color(0xFFCA8A04),
            'Sedang'
          ),
        'low' => (const Color(0xFFDCFCE7), const Color(0xFF16A34A), 'Rendah'),
        'done' => (const Color(0xFFF3F4F6), const Color(0xFF6B7280), 'Selesai'),
        _ => (const Color(0xFFF3F4F6), const Color(0xFF6B7280), 'Tugas'),
      };
}
