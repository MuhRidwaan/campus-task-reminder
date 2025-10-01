import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/task_provider.dart';

// Halaman baru untuk mengatur nama mata kuliah
class CourseSettingsPage extends StatefulWidget {
  final List<String> courseCategories;

  const CourseSettingsPage({super.key, required this.courseCategories});

  @override
  State<CourseSettingsPage> createState() => _CourseSettingsPageState();
}

class _CourseSettingsPageState extends State<CourseSettingsPage> {
  late SharedPreferences _prefs;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadCourseNames();
  }

  Future<void> _loadCourseNames() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var category in widget.courseCategories) {
        final savedName = _prefs.getString('course_name_$category') ?? '';
        _controllers[category] = TextEditingController(text: savedName);
      }
    });
  }

  Future<void> _saveCourseName(String category, String name) async {
    await _prefs.setString('course_name_$category', name.trim());
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Nama Mata Kuliah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Muat ulang nama di provider setelah disimpan
              context.read<TaskProvider>().loadCourseNames();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nama mata kuliah disimpan!')),
              );
            },
          )
        ],
      ),
      body: widget.courseCategories.isEmpty
          ? const Center(child: Text('Tidak ada mata kuliah untuk diatur.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.courseCategories.length,
              itemBuilder: (context, index) {
                final category = widget.courseCategories[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextField(
                    controller: _controllers[category],
                    decoration: InputDecoration(
                      labelText:
                          'Nama untuk ID: ...${category.substring(category.length - 6)}',
                      border: const OutlineInputBorder(),
                      hintText: 'Contoh: Kecerdasan Buatan',
                    ),
                    onChanged: (value) => _saveCourseName(category, value),
                  ),
                );
              },
            ),
    );
  }
}
