import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/task/task_card.dart';
import '../categories/category_screen.dart';
import '../profile/profile_screen.dart';
import 'task_form_screen.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
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
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  void _onTabChanged(int idx) {
    setState(() => _selectedTab = idx);
    final taskProv = context.read<TaskProvider>();
    switch (idx) {
      case 0:
        taskProv.setFilter();
        break;
      case 1:
        taskProv.fetchTasks(date: DateTime.now().toString().split(' ')[0]);
        break;
      case 2:
        taskProv.setFilter(status: 'todo');
        break;
      case 3:
        taskProv.setFilter(status: 'done');
        break;
    }
  }

  Widget _buildProductivityDashboard(TaskProvider prov) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (prov.completionRate * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Dashboard Produktivitas',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: prov.completionRate,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DashboardMetric(
                    icon: Icons.check_circle_outline,
                    label: 'Selesai',
                    value: '${prov.doneCount}',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _DashboardMetric(
                    icon: Icons.pending_actions_rounded,
                    label: 'Belum',
                    value: '${prov.pendingCount}',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _DashboardMetric(
                    icon: Icons.today_rounded,
                    label: 'Hari Ini',
                    value: '${prov.todayCount}',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _DashboardMetric(
                    icon: Icons.warning_amber_rounded,
                    label: 'Lewat',
                    value: '${prov.overdueCount}',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tiga state logic _buildBody()
  Widget _buildBody(TaskProvider prov) {
    if (prov.state == TaskState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.state == TaskState.error) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 8),
        Text(prov.errorMessage ?? 'Terjadi kesalahan'),
        TextButton(
            onPressed: () => prov.fetchTasks(), child: const Text('Coba Lagi')),
      ]));
    }
    if (prov.tasks.isEmpty) {
      return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.task_alt, size: 64, color: Colors.grey),
        SizedBox(height: 12),
        Text('Belum ada task', style: TextStyle(color: Colors.grey)),
      ]));
    }
    return ListView.builder(
      itemCount: prov.tasks.length,
      itemBuilder: (_, i) => TaskCard(
        task: prov.tasks[i],
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TaskDetailScreen(taskId: prov.tasks[i].id))),
        onStatusChanged: (status) =>
            prov.updateStatus(prov.tasks[i].id, status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final task = context.watch<TaskProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${auth.user?.name.split(' ').first ?? ''} 👋'),
        actions: [
          IconButton(
              icon: const Icon(Icons.category_outlined),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CategoryScreen()))),
          IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()))),
        ],
      ),
      body: Column(children: [
        _buildProductivityDashboard(task),
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: task.search,
            decoration: InputDecoration(
              hintText: 'Cari task...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        // Tab filter
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: List.generate(
                    _tabs.length,
                    (i) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_tabs[i]),
                            selected: _selectedTab == i,
                            onSelected: (_) => _onTabChanged(i),
                          ),
                        ))),
          ),
        ),
        Expanded(child: _buildBody(task)),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TaskFormScreen(isEdit: false)));
          task.fetchTasks();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Task'),
      ),
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DashboardMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
