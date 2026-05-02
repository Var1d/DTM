import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  final String? priority;
  const PriorityBadge({super.key, this.priority});

  @override
  Widget build(BuildContext context) {
    final cfg = _config(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        cfg.$1.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: cfg.$1.withOpacity(0.4)),
      ),
      child: Text(cfg.$2, style: TextStyle(fontSize: 11, color: cfg.$1, fontWeight: FontWeight.w600)),
    );
  }

  // (color, label)
  static (Color, String) _config(String? p) => switch (p) {
    'overdue'  => (Colors.red,         '🔴 Terlambat'),
    'critical' => (Colors.deepOrange,  '🔥 Kritis'),
    'high'     => (Colors.orange,      '⚠️ Tinggi'),
    'medium'   => (Colors.amber,       '🟡 Sedang'),
    'low'      => (Colors.green,       '🟢 Rendah'),
    _          => (Colors.grey,        '⬜ Tanpa Deadline'),
  };
}
