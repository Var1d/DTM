import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../providers/category_provider.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<CategoryProvider>().fetchCategories());
  }

  void _showForm({int? id, String name = '', String color = '#6366f1'}) {
    final nameCtrl = TextEditingController(text: name);
    Color picked = Color(int.parse('0xFF${color.replaceAll('#', '')}'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
          builder: (ctx, setModal) => Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(id == null ? 'Tambah Kategori' : 'Edit Kategori',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                          labelText: 'Nama Kategori',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                  // Color picker
                  BlockPicker(
                    pickerColor: picked,
                    onColorChanged: (c) => setModal(() => picked = c),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final hex =
                              '#${picked.toARGB32().toRadixString(16).substring(2)}';
                          final prov = context.read<CategoryProvider>();
                          if (id == null) {
                            await prov.createCategory(
                                nameCtrl.text.trim(), hex);
                          } else {
                            await prov.updateCategory(
                                id, nameCtrl.text.trim(), hex);
                          }
                          if (mounted) Navigator.pop(context);
                        },
                        child: Text(id == null ? 'Tambah' : 'Simpan'),
                      )),
                ]),
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CategoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      body: ListView.builder(
        itemCount: prov.categories.length,
        itemBuilder: (_, i) {
          final c = prov.categories[i];
          final color = Color(int.parse('0xFF${c.color.replaceAll('#', '')}'));
          return ListTile(
            leading: CircleAvatar(backgroundColor: color, radius: 14),
            title: Text(c.name),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      _showForm(id: c.id, name: c.name, color: c.color)),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => prov.deleteCategory(c.id)),
            ]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
