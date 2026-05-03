import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
    });
  }

  Future<void> _showCourseDialog({CourseModel? course}) async {
    final nameCtrl = TextEditingController(text: course?.name ?? '');
    final lecturerCtrl = TextEditingController(text: course?.lecturer ?? '');
    final roomCtrl = TextEditingController(text: course?.room ?? '');
    final creditCtrl = TextEditingController(text: '${course?.credit ?? 3}');
    String? day = course?.day;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              course == null ? 'Tambah Mata Kuliah' : 'Edit Mata Kuliah',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Mata Kuliah'),
            ),
            TextField(
              controller: lecturerCtrl,
              decoration: const InputDecoration(labelText: 'Dosen'),
            ),
            TextField(
              controller: roomCtrl,
              decoration: const InputDecoration(labelText: 'Ruangan'),
            ),
            DropdownButtonFormField<String>(
              initialValue: day,
              decoration: const InputDecoration(labelText: 'Hari Kuliah'),
              items: const [
                DropdownMenuItem(value: 'Senin', child: Text('Senin')),
                DropdownMenuItem(value: 'Selasa', child: Text('Selasa')),
                DropdownMenuItem(value: 'Rabu', child: Text('Rabu')),
                DropdownMenuItem(value: 'Kamis', child: Text('Kamis')),
                DropdownMenuItem(value: 'Jumat', child: Text('Jumat')),
                DropdownMenuItem(value: 'Sabtu', child: Text('Sabtu')),
                DropdownMenuItem(value: 'Minggu', child: Text('Minggu')),
              ],
              onChanged: (value) => day = value,
            ),
            TextField(
              controller: creditCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'SKS'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan'),
              onPressed: () async {
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mata Kuliah')),
      body: provider.state == CourseState.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, i) {
                final course = provider.courses[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(course.name.isEmpty ? '?' : course.name[0]),
                  ),
                  title: Text(course.name),
                  subtitle: Text(
                    [
                      if (course.day != null) course.day,
                      if (course.room != null) course.room,
                      '${course.doneCount}/${course.taskCount} tugas selesai',
                    ].join(' - '),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showCourseDialog(course: course),
                  ),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: provider.courses.length,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}
