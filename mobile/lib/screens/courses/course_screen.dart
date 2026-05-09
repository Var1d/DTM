import 'package:flutter/material.dart';
import '../../widgets/common/loading_logo.dart';
import 'package:provider/provider.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/color_helper.dart';

/// ============================================================
/// CourseScreen — Halaman pengelolaan data mata kuliah.
/// Menampilkan daftar mata kuliah dalam bentuk kartu (card)
/// serta menyediakan formulir penambahan dan penyuntingan data.
///
/// Fitur:
///  • Pencarian mata kuliah
///  • Sorting: Alphabet (A-Z), Total Tugas, SKS
///  • Filter SKS via dropdown
///  • Default: diurutkan berdasarkan alfabet
/// ============================================================
class CourseScreen extends StatefulWidget {
  final bool isMain;
  const CourseScreen({super.key, this.isMain = false});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

/// Enum untuk opsi sorting
enum _SortBy { alphabet, taskCount, sks }

class _CourseScreenState extends State<CourseScreen> {
  final _searchCtrl = TextEditingController();
  _SortBy _sortBy = _SortBy.alphabet;
  bool _sortAscending = true;
  int? _filterSks; // null = semua SKS

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Menghasilkan daftar SKS unik dari daftar mata kuliah
  List<int> _getUniqueSks(List<CourseModel> courses) {
    final sksSet = courses.map((c) => c.credit).toSet().toList();
    sksSet.sort();
    return sksSet;
  }

  /// Menerapkan pencarian, filter SKS, dan sorting pada daftar mata kuliah
  List<CourseModel> _applyFilterAndSort(List<CourseModel> courses) {
    var result = List<CourseModel>.from(courses);

    // 1. Filter pencarian
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((c) =>
        c.name.toLowerCase().contains(query) ||
        (c.lecturer?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // 2. Filter SKS
    if (_filterSks != null) {
      result = result.where((c) => c.credit == _filterSks).toList();
    }

    // 3. Sorting
    result.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case _SortBy.alphabet:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case _SortBy.taskCount:
          cmp = a.taskCount.compareTo(b.taskCount);
          break;
        case _SortBy.sks:
          cmp = a.credit.compareTo(b.credit);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return result;
  }

  /// Label sorting untuk tampilan UI
  String get _sortLabel => switch (_sortBy) {
    _SortBy.alphabet => 'A-Z',
    _SortBy.taskCount => 'Tugas',
    _SortBy.sks => 'SKS',
  };

  /// Menampilkan dialog form untuk menambah atau mengubah data mata kuliah.
  Future<void> _showCourseDialog({CourseModel? course}) async {
    final nameCtrl = TextEditingController(text: course?.name ?? '');
    final lecturerCtrl = TextEditingController(text: course?.lecturer ?? '');
    final roomCtrl = TextEditingController(text: course?.room ?? '');
    final creditCtrl = TextEditingController(text: '${course?.credit ?? 3}');
    String? day = course?.day;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Form Modal
                Text(
                  course == null ? 'Tambah Mata Kuliah' : 'Edit Mata Kuliah',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Field Nama Mata Kuliah
                _buildLabel(context, 'Nama Mata Kuliah *'),
                const SizedBox(height: 6),
                TextField(controller: nameCtrl),
                const SizedBox(height: 12),

                // Field Dosen
                _buildLabel(context, 'Dosen'),
                const SizedBox(height: 6),
                TextField(controller: lecturerCtrl),
                const SizedBox(height: 12),

                // Field Ruangan
                _buildLabel(context, 'Ruangan'),
                const SizedBox(height: 6),
                TextField(controller: roomCtrl),
                const SizedBox(height: 12),

                // Baris Hari + SKS
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(context, 'Hari'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: day,
                            decoration: const InputDecoration(isDense: true),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Fleksibel')),
                              DropdownMenuItem(value: 'Senin', child: Text('Senin')),
                              DropdownMenuItem(value: 'Selasa', child: Text('Selasa')),
                              DropdownMenuItem(value: 'Rabu', child: Text('Rabu')),
                              DropdownMenuItem(value: 'Kamis', child: Text('Kamis')),
                              DropdownMenuItem(value: 'Jumat', child: Text('Jumat')),
                              DropdownMenuItem(value: 'Sabtu', child: Text('Sabtu')),
                            ],
                            onChanged: (v) => setModalState(() => day = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(context, 'SKS'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: creditCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tombol Aksi Form
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Batal',
                        outlined: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        label: course == null ? 'Tambah' : 'Simpan',
                        onPressed: () async {
                          final color = ColorHelper.toHex(ColorHelper.fromString(nameCtrl.text.trim()));
                          final data = {
                            'name': nameCtrl.text.trim(),
                            'lecturer': lecturerCtrl.text.trim().isEmpty
                                ? null
                                : lecturerCtrl.text.trim(),
                            'room': roomCtrl.text.trim().isEmpty
                                ? null
                                : roomCtrl.text.trim(),
                            'day': day,
                            'credit': int.tryParse(creditCtrl.text) ?? 3,
                            'color': color,
                          };
                          final provider = context.read<CourseProvider>();
                          if (course == null) {
                            await provider.createCourse(data);
                          } else {
                            await provider.updateCourse(course.id, data);
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    // Terapkan filter dan sorting
    final filtered = _applyFilterAndSort(provider.courses);
    final uniqueSks = _getUniqueSks(provider.courses);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.isMain ? null : AppBar(backgroundColor: Colors.transparent, title: const Text('Mata Kuliah')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seksi Header Halaman: Judul dan Deskripsi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mata Kuliah',
                        style: Theme.of(context).textTheme.titleLarge),
                    // Badge jumlah mata kuliah
                    if (provider.courses.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${provider.courses.length} matkul',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola jadwal dan konteks tugas tiap mata kuliah.',
                  style: TextStyle(color: mutedColor, fontSize: 13),
                ),
              ],
            ),
          ),

          // Seksi Pencarian + Filter
          if (provider.courses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  // Baris 1: Pencarian
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari mata kuliah atau dosen...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Baris 2: Sort + Filter SKS
                  Row(
                    children: [
                      // Tombol Sort
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showSortMenu(context, isDark),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                              color: isDark
                                  ? AppTheme.bgElevatedDark
                                  : AppTheme.bgElevatedLight,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.sort_rounded, size: 16, color: primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Urut: $_sortLabel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppTheme.textDark : AppTheme.textLight,
                                    ),
                                  ),
                                ),
                                // Tombol toggle arah sorting
                                GestureDetector(
                                  onTap: () => setState(() => _sortAscending = !_sortAscending),
                                  child: Icon(
                                    _sortAscending
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    size: 14,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Filter SKS dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                            color: isDark
                                ? AppTheme.bgElevatedDark
                                : AppTheme.bgElevatedLight,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: _filterSks,
                              isExpanded: true,
                              isDense: true,
                              icon: Icon(Icons.expand_more, size: 18, color: mutedColor),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.textDark : AppTheme.textLight,
                              ),
                              items: [
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Row(
                                    children: [
                                      Icon(Icons.school_outlined, size: 14, color: primary),
                                      const SizedBox(width: 6),
                                      const Text('Semua SKS'),
                                    ],
                                  ),
                                ),
                                ...uniqueSks.map((sks) => DropdownMenuItem<int?>(
                                  value: sks,
                                  child: Text('$sks SKS'),
                                )),
                              ],
                              onChanged: (val) => setState(() => _filterSks = val),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 4),

          // Seksi Konten: Daftar Mata Kuliah
          Expanded(
            child: provider.state == CourseState.loading && provider.courses.isEmpty
                ? const Center(child: LoadingLogo(size: 56))
                : provider.courses.isEmpty
                    // Tampilan jika data kosong
                    ? Center(
                        child: GlassCard(
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📚', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text('Belum ada mata kuliah',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(
                                'Tambahkan mata kuliah dulu supaya tugas bisa terstruktur.',
                                style: TextStyle(color: mutedColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              CustomButton(
                                label: '+ Tambah Mata Kuliah',
                                onPressed: () => _showCourseDialog(),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        // Tampilan jika hasil pencarian/filter kosong
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: mutedColor),
                                const SizedBox(height: 12),
                                Text('Tidak ada hasil',
                                    style: TextStyle(color: mutedColor, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Coba ubah kata kunci atau filter.',
                                    style: TextStyle(color: mutedColor, fontSize: 12)),
                              ],
                            ),
                          )
                        // Daftar kartu mata kuliah menggunakan ListView
                        : RefreshIndicator(
                            onRefresh: () => provider.fetchCourses(),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _buildCourseCard(filtered[i], isDark, mutedColor),
                            ),
                          ),
          ),
        ],
      ),
      // Tombol Aksi Tambah Mata Kuliah Baru
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.primaryGradientDark : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showCourseDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Tambah Mata Kuliah',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  /// Menu popup untuk memilih opsi sorting
  void _showSortMenu(BuildContext context, bool isDark) {
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final items = [
      (_SortBy.alphabet, 'Alfabet (A-Z)', Icons.sort_by_alpha_rounded),
      (_SortBy.taskCount, 'Total Tugas', Icons.assignment_rounded),
      (_SortBy.sks, 'Jumlah SKS', Icons.school_rounded),
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
              final isActive = _sortBy == item.$1;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(item.$3,
                    color: isActive ? primary : null, size: 20),
                title: Text(item.$2,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? primary : null,
                    )),
                trailing: isActive
                    ? Icon(Icons.check_circle, color: primary, size: 20)
                    : null,
                onTap: () {
                  setState(() => _sortBy = item.$1);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu individual untuk setiap mata kuliah.
  Widget _buildCourseCard(CourseModel course, bool isDark, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indikator Warna Mata Kuliah
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Color(int.parse(course.color.replaceFirst('#', '0xFF'))),
              ),
            ),
            const SizedBox(width: 12),
            // Info mata kuliah
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama + Badge SKS
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0x1FFFFFFF)
                              : const Color(0x14000000),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${course.credit} SKS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: mutedColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [course.lecturer, course.room]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' - ')
                            .isEmpty
                        ? 'Detail belum diisi'
                        : [course.lecturer, course.room]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' - '),
                    style: TextStyle(color: mutedColor, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course.taskCount} tugas, ${course.doneCount} selesai',
                    style: TextStyle(color: mutedColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Tombol Aksi Kartu (Edit & Hapus)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ghostButton('Edit', () => _showCourseDialog(course: course), isDark),
                const SizedBox(height: 6),
                _outlineButton('Hapus', () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Mata Kuliah?'),
                      content: Text(
                          'Apakah Anda yakin ingin menghapus "${course.name}"? Semua tugas di dalamnya juga akan terhapus.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Hapus',
                              style: TextStyle(
                                  color: isDark
                                      ? AppTheme.dangerDark
                                      : AppTheme.dangerLight)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await context
                        .read<CourseProvider>()
                        .deleteCourse(course.id);
                  }
                }, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Tombol bergaya 'Ghost' untuk aksi sekunder.
  Widget _ghostButton(String label, VoidCallback onTap, bool isDark) {
    final primary = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textDark : AppTheme.textLight)),
      ),
    );
  }

  /// Tombol bergaya 'Outline' untuk aksi sekunder lainnya.
  Widget _outlineButton(String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textDark : AppTheme.textLight)),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
        ));
  }
}
