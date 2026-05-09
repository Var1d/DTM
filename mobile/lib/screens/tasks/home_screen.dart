import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/task/task_card.dart';
import '../courses/course_screen.dart';
import '../profile/profile_screen.dart';
import '../stats/stats_screen.dart';
import 'task_form_screen.dart';
import 'task_detail_screen.dart';

/// ============================================================
/// HomeScreen — Halaman utama aplikasi (Board Tugas).
/// Menampilkan ringkasan produktivitas, filter mata kuliah,
/// fitur pencarian, dan daftar tugas akademik pengguna.
/// ============================================================
class HomeScreen extends StatefulWidget {
  final bool isMain;
  const HomeScreen({super.key, this.isMain = false});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  int _selectedTab = 0;
  final _tabs = ['Semua', 'Hari Ini', 'Belum', 'Selesai'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
      context.read<CourseProvider>().fetchCourses();
    });
  }

  /// Menangani perubahan tab filter kategori tugas
  void _onTabChanged(int idx) {
    setState(() => _selectedTab = idx);
    final taskProv = context.read<TaskProvider>();
    switch (idx) {
      case 0:
        taskProv.setFilter(priority: taskProv.filterPriority);
        break;
      case 1:
        taskProv.setFilter(
            date: DateTime.now().toIso8601String().split('T')[0],
            priority: taskProv.filterPriority);
        break;
      case 2:
        taskProv.setFilter(status: 'not_done', priority: taskProv.filterPriority);
        break;
      case 3:
        taskProv.setFilter(status: 'done', priority: taskProv.filterPriority);
        break;
    }
  }

  /// Label sorting untuk tampilan UI
  String _sortLabel(TaskSortBy sortBy) => switch (sortBy) {
    TaskSortBy.smartPriority => 'Prioritas',
    TaskSortBy.deadline => 'Deadline',
    TaskSortBy.gradeWeight => 'Bobot',
    TaskSortBy.alphabet => 'A-Z',
  };

  /// Menu popup sorting
  void _showSortMenu(BuildContext context, bool isDark) {
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final taskProv = context.read<TaskProvider>();
    final items = [
      (TaskSortBy.smartPriority, 'Prioritas Cerdas', Icons.auto_awesome_rounded),
      (TaskSortBy.deadline, 'Deadline Terdekat', Icons.schedule_rounded),
      (TaskSortBy.gradeWeight, 'Bobot Nilai', Icons.bar_chart_rounded),
      (TaskSortBy.alphabet, 'Alfabet (A-Z)', Icons.sort_by_alpha_rounded),
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Urutkan Berdasarkan',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...items.map((item) {
              final isActive = taskProv.sortBy == item.$1;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(item.$3, color: isActive ? primary : null, size: 20),
                title: Text(item.$2,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? primary : null,
                    )),
                trailing: isActive
                    ? Icon(Icons.check_circle, color: primary, size: 20)
                    : null,
                onTap: () {
                  taskProv.setSort(item.$1);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final task = context.watch<TaskProvider>();
    final courses = context.watch<CourseProvider>().courses;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow gradient to show
      // AppBar hanya muncul jika bukan bagian dari MainScreen
      appBar: widget.isMain
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              title: Text('Halo, ${auth.user?.name.split(' ').first ?? ''} 👋'),
              actions: [
                IconButton(
                    icon: const Icon(Icons.school_outlined),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CourseScreen()))),
                IconButton(
                    icon: const Icon(Icons.person_outline),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()))),
              ],
            ),
      body: Column(
        children: [
          // Seksi Header: Judul dan Ringkasan Produktivitas
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: GlassCard(
              useGradient: true,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PIO Task Board',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const StatsScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.auto_graph_rounded,
                                  size: 14, color: primary),
                              const SizedBox(width: 4),
                              Text('Statistik',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola tugas akademikmu dengan mudah dan cepat.',
                    style: TextStyle(color: mutedColor, fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  // Dashboard Produktivitas
                  _buildProductivityRow(task, isDark),
                ],
              ),
            ),
          ),

          // Seksi Filter: Dropdown Mata Kuliah & Bar Pencarian
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // Filter Dropdown Mata Kuliah
                Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<int?>(
                    value: task.filterCourseId,
                    isExpanded: true, // Mencegah teks meluap
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                      hintText: 'Mata Kuliah',
                      prefixIcon:
                          Icon(Icons.school_outlined, size: 18, color: primary),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Semua Matkul',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      ...courses.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) => task.setFilter(
                      courseId: val,
                      status: task.filterStatus,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter Pencarian Judul Tugas
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: task.search,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Cari tugas...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Seksi Tab Kategori (Chips) — Seimbang kiri-kanan
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Row(
                  children: List.generate(
                    _tabs.length,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 3,
                          right: i == _tabs.length - 1 ? 0 : 3,
                        ),
                        child: FilterChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(_tabs[i], textAlign: TextAlign.center),
                          ),
                          selected: _selectedTab == i,
                          onSelected: (_) => _onTabChanged(i),
                        ),
                      ),
                    ),
                  ),
                ),
                // Indikator Offline
                if (task.state == TaskState.loaded && task.errorMessage != null)
                  Positioned(
                    right: 0,
                    top: -4,
                    child: Tooltip(
                      message: task.errorMessage!,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_off_rounded, size: 14, color: Colors.orange.withOpacity(0.8)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Seksi Sorting + Filter Prioritas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                // Tombol Sort
                GestureDetector(
                  onTap: () => _showSortMenu(context, isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                      color: isDark ? AppTheme.bgElevatedDark : AppTheme.bgElevatedLight,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort_rounded, size: 14, color: primary),
                        const SizedBox(width: 4),
                        Text(
                          _sortLabel(task.sortBy),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.textDark : AppTheme.textLight),
                        ),
                        const SizedBox(width: 2),
                        GestureDetector(
                          onTap: () => task.toggleSortDirection(),
                          child: Icon(
                            task.sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12, color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Filter Prioritas (scrollable chips)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _priorityChip(context, null, 'Semua', task, isDark),
                        _priorityChip(context, 'critical', 'Kritis', task, isDark),
                        _priorityChip(context, 'high', 'Tinggi', task, isDark),
                        _priorityChip(context, 'medium', 'Sedang', task, isDark),
                        _priorityChip(context, 'low', 'Rendah', task, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Daftar Tugas Akademik
          Expanded(child: _buildBody(task, isDark)),
        ],
      ),
      // Tombol Aksi Tambah Tugas
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient:
              isDark ? AppTheme.primaryGradientDark : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                  .withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TaskFormScreen(isEdit: false)));
            task.fetchTasks();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Tambah Tugas',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  /// Widget Dashboard Produktivitas: Progress bar dan metrik statistik tugas.
  Widget _buildProductivityRow(TaskProvider prov, bool isDark) {
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final percent = (prov.completionRate * 100).round();

    return Column(
      children: [
        // Progress bar dengan persentase
        Row(
          children: [
            Icon(Icons.insights_rounded, color: primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: prov.completionRate,
                  minHeight: 6,
                  backgroundColor:
                      (isDark ? AppTheme.bgSoftDark : AppTheme.bgSoftLight),
                  valueColor: AlwaysStoppedAnimation(primary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$percent%',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Metrik statistik
        Row(
          children: [
            _metric(Icons.check_circle_outline_rounded, '${prov.doneCount}',
                'Selesai', Colors.green),
            _metric(Icons.pending_actions_rounded, '${prov.pendingCount}',
                'Belum', Colors.orange),
            _metric(Icons.calendar_today_rounded, '${prov.todayCount}',
                'Hari Ini', Colors.blue),
            _metric(Icons.error_outline_rounded, '${prov.criticalCount}',
                'Genting', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _metric(IconData icon, String value, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: TextStyle(fontSize: 10, color: mutedColor)),
        ],
      ),
    );
  }

  /// Chip filter prioritas kecil
  Widget _priorityChip(BuildContext context, String? priority, String label,
      TaskProvider prov, bool isDark) {
    final isActive = prov.filterPriority == priority;
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    // Warna per prioritas
    final chipColor = switch (priority) {
      'critical' => Colors.red,
      'high' => Colors.orange,
      'medium' => Colors.blue,
      'low' => Colors.green,
      _ => primary,
    };

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () {
          prov.setFilter(
            status: prov.filterStatus,
            courseId: prov.filterCourseId,
            priority: priority,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isActive ? chipColor.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(
              color: isActive ? chipColor : borderColor,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? chipColor : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun body utama berdasarkan status data (Loading, Error, atau List).
  Widget _buildBody(TaskProvider prov, bool isDark) {
    final mutedColor =
        isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;

    // Jika data kosong dan sedang loading pertama kali, tampilkan container kosong (biar instan)
    // Jika sudah ada data, biarkan data lama tampil selagi fetch di background
    if (prov.state == TaskState.loading && prov.tasks.isEmpty) {
      return const SizedBox();
    }
    if (prov.state == TaskState.error) {
      return Center(
        child: GlassCard(
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: isDark ? AppTheme.dangerDark : AppTheme.dangerLight),
              const SizedBox(height: 8),
              Text(prov.errorMessage ?? 'Terjadi kesalahan'),
              TextButton(
                  onPressed: () => prov.fetchTasks(),
                  child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    // Tampilan jika daftar tugas kosong
    if (prov.tasks.isEmpty) {
      return Center(
        child: GlassCard(
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📋', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Belum ada tugas yang cocok',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Coba ubah filter atau tambah tugas baru.',
                style: TextStyle(color: mutedColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => prov.fetchTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        cacheExtent: 500, // Pre-render cards offscreen untuk scroll lebih halus
        itemCount: prov.tasks.length,
        itemBuilder: (_, i) {
          final task = prov.tasks[i];
          return TaskCard(
            task: task,
            onTap: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(
                            taskId: task.id,
                            task: task,
                          )));
              if (context.mounted) {
                prov.fetchTasks();
                context.read<CourseProvider>().refreshSilent();
              }
            },
            onStatusChanged: (status) {
              prov.updateStatus(task.id, status);
              // Optimistic update ke matkul terkait biar statistik instan
              context.read<CourseProvider>().optimisticUpdateTaskStatus(
                  task.courseId, status == 'done');
            },
          );
        },
      ),
    );
  }
}
