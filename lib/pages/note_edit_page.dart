import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../providers/task_provider.dart';

class NoteEditPage extends StatefulWidget {
  final Note? note;

  const NoteEditPage({super.key, this.note});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedCategoryId = widget.note!.courseCategoryId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text;
    final content = _contentController.text;

    if (title.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Judul dan Mata Kuliah tidak boleh kosong!')),
      );
      return;
    }

    final noteProvider = context.read<NoteProvider>();

    if (widget.note == null) {
      noteProvider.addNote(title, content, _selectedCategoryId!);
    } else {
      final updatedNote = Note(
        id: widget.note!.id,
        title: title,
        content: content,
        courseCategoryId: _selectedCategoryId!,
        lastModified: DateTime.now(),
      );
      noteProvider.updateNote(updatedNote);
    }
    Navigator.pop(context);
  }

  void _deleteNote() {
    if (widget.note != null) {
      context.read<NoteProvider>().deleteNote(widget.note!.id);
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    final Map<String, String> courseOptions = {
      'general': 'Catatan Umum',
    };
    for (var categoryId in taskProvider.uniqueCategories) {
      courseOptions[categoryId] = taskProvider.courseNames[categoryId] ??
          'ID: ...${categoryId.substring(categoryId.length - 8)}';
    }

    final courseItems = courseOptions.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Catatan Baru' : 'Edit Catatan'),
        actions: [
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteNote,
              tooltip: 'Hapus',
            ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveNote,
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              hint: const Text('Pilih Kategori/Mata Kuliah'),
              items: courseItems,
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Catatan',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Isi Catatan...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
