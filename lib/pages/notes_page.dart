import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../providers/note_provider.dart';
import '../providers/task_provider.dart';
import 'note_edit_page.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Kuliah'),
      ),
      body: Consumer2<NoteProvider, TaskProvider>(
        builder: (context, noteProvider, taskProvider, child) {
          if (noteProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (noteProvider.notes.isEmpty) {
            return const Center(
              child: Text('Belum ada catatan.\nTekan tombol + untuk membuat.'),
            );
          }

          final groupedNotes =
              groupBy(noteProvider.notes, (Note note) => note.courseCategoryId);
          final sortedKeys = groupedNotes.keys.toList()
            ..sort((a, b) {
              if (a == 'general') return -1; // "Catatan Umum" selalu di atas
              if (b == 'general') return 1;
              return (taskProvider.courseNames[a] ?? a)
                  .compareTo(taskProvider.courseNames[b] ?? b);
            });

          return ListView.builder(
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final categoryId = sortedKeys[index];
              final notesForCategory = groupedNotes[categoryId]!;
              final courseName = taskProvider.courseNames[categoryId] ??
                  (categoryId == 'general' ? 'Catatan Umum' : 'Lainnya');

              return ExpansionTile(
                title: Text(courseName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                initiallyExpanded: true,
                children: notesForCategory.map((note) {
                  return ListTile(
                    title: Text(note.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NoteEditPage(note: note)),
                      );
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteEditPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
