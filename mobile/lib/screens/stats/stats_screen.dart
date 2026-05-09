import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/course_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/main_background.dart';

/// ============================================================
/// StatsScreen — Dashboard Statistik Akademik.
/// Menampilkan ringkasan performa akademik pengguna, termasuk
/// tingkat penyelesaian tugas, rata-rata nilai, dan progres SKS.
///
/// Diubah ke StatefulWidget agar bisa merefresh data saat dibuka
/// dan mendukung pull-to-refresh.
/// ============================================================
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data saat halaman dibuka agar selalu terkini
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
      context.read<CourseProvider>().fetchCourses();
    });
  }

  Future<void> _refresh() async {
    await context.read<TaskProvider>().fetchTasks();
    if (mounted) await context.read<CourseProvider>().fetchCourses();
  }

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final courseProv = context.watch<CourseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final mutedColor = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    final titleColor = isDark ? AppTheme.textDark : AppTheme.textLight;

    return MainBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Statistik Akademik'),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Ringkasan Utama (Circular Progress) ──
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: taskProv.completionRate,
                              strokeWidth: 8,
                              backgroundColor: primary.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation(primary),
                            ),
                          ),
                          Text(
                            '${(taskProv.completionRate * 100).round()}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tingkat Penyelesaian',
                              style: TextStyle(color: mutedColor, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${taskProv.doneCount} dari ${taskProv.totalCount} Tugas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              taskProv.completionRate >= 0.8
                                  ? 'Performa Luar Biasa! 🔥'
                                  : taskProv.completionRate >= 0.5
                                      ? 'Tetap Semangat! 👍'
                                      : 'Ayo Mulai Mencicil! 📚',
                              style: TextStyle(
                                fontSize: 12,
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
    
                // ── Grid Metrik (Skor & SKS) ──
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        'Rata-rata Nilai',
                        taskProv.averageScore.toStringAsFixed(1),
                        'Berdasarkan tugas selesai',
                        Icons.auto_graph_rounded,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
                        'SKS Terpantau',
                        '${courseProv.completedSks}/${courseProv.totalSks}',
                        'Dari total matkul',
                        Icons.school_rounded,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
    
                // ── Progres Bobot Nilai (Grade Weight) ──
                Text('Progres Bobot Nilai Semester',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    )),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Bobot Selesai',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, color: titleColor)),
                          Text(
                            '${taskProv.completedGradeWeight.round()}% / ${taskProv.totalGradeWeight.round()}%',
                            style: TextStyle(
                                color: primary, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: taskProv.totalGradeWeight > 0
                              ? taskProv.completedGradeWeight /
                                  taskProv.totalGradeWeight
                              : 0,
                          minHeight: 12,
                          backgroundColor: primary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Persentase ini menunjukkan seberapa besar andil tugas yang sudah selesai terhadap nilai akhir semester Anda.',
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                    ],
                  ),
                ),
    
                const SizedBox(height: 24),
                // ── Statistik per Mata Kuliah ──
                Text('Distribusi Tugas per Matkul',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    )),
                const SizedBox(height: 12),
                ...courseProv.courses
                    .map((c) => _courseRow(context, c, isDark, mutedColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, String sub,
      IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final mutedColor = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: titleColor)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: titleColor)),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(fontSize: 11, color: mutedColor)),
        ],
      ),
    );
  }

  Widget _courseRow(
      BuildContext context, dynamic course, bool isDark, Color muted) {
    final titleColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final courseColor = Color(int.parse(course.color.replaceFirst('#', '0xFF')));
    final progress =
        course.taskCount > 0 ? course.doneCount / course.taskCount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 34,
              decoration: BoxDecoration(
                color: courseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: titleColor)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.toDouble(),
                      minHeight: 4,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation(courseColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${course.doneCount}/${course.taskCount}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: titleColor)),
                Text('Selesai', style: TextStyle(fontSize: 10, color: muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
