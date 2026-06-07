// lib/screens/categories_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import '../database/boxes.dart';
import '../models/category.dart';
import '../utils/constants_shared.dart';

class CategoriesManagementScreen extends ConsumerStatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  ConsumerState<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends ConsumerState<CategoriesManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  CategoryType _type = CategoryType.expense;
  final IconData _icon = Icons.category;
  final Color _color = Colors.blue;

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Category'),
        content: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              onSaved: (v) => _name = v!.trim(),
            ),
            DropdownButtonFormField<CategoryType>(
              initialValue: _type,
              items: CategoryType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.capitalize()))).toList(),
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            // Icon & Color pickers could be more sophisticated; using defaults for brevity.
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addCategory, child: const Text('Add')),
        ],
      ),
    );
  }

  Future<void> _addCategory() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final box = Hive.box<Category>(Boxes.categories);
    final newCat = Category(
      id: UniqueKey().toString(),
      name: _name,
      iconCodePoint: _icon.codePoint.toString(),
      colorValue: _color.toARGB32(),
      type: _type,
      isDefault: false,
    );
    await box.put(newCat.id, newCat);
    setState(() {});
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = Hive.box<Category>(Boxes.categories).values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Categories'), backgroundColor: AppConstants.primaryColor),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (c, i) {
          final cat = categories[i];
          return ListTile(
            leading: Icon(IconData(int.parse(cat.iconCodePoint), fontFamily: 'MaterialIcons')),
            title: Text(cat.name),
            subtitle: Text(cat.type.name.capitalize()),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await Hive.box<Category>(Boxes.categories).delete(cat.id);
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }
}

extension StringCap on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}
