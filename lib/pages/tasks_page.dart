import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'task_detail_page.dart';
import '../providers/task_provider.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Daftar Tugas'),
            actions: [
              PopupMenuButton<TaskFilter>(
                icon: const Icon(Icons.filter_list),
                onSelected: (TaskFilter filter) {
                  taskProvider.setFilter(filter);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<TaskFilter>>[
                  const PopupMenuItem<TaskFilter>(
                    value: TaskFilter.upcoming,
                    child: Text('Akan Datang'),
                  ),
                  const PopupMenuItem<TaskFilter>(
                    value: TaskFilter.all,
                    child: Text('Tampilkan Semua'),
                  ),
                  const PopupMenuItem<TaskFilter>(
                    value: TaskFilter.completed,
                    child: Text('Selesai'),
                  ),
                  const PopupMenuItem<TaskFilter>(
                    value: TaskFilter.overdue,
                    child: Text('Terlewat'),
                  ),
                ],
              ),
            ],
          ),
          body: Stack(
            children: [
              _buildBody(context, taskProvider),
              if (taskProvider.isOffline)
                const Material(
                  color: Colors.transparent,
                  child: Banner(
                    message: "OFFLINE",
                    location: BannerLocation.topStart,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TaskProvider taskProvider) {
    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskProvider.error != null && taskProvider.tasks.isEmpty) {
      return Center(child: Text('Error: ${taskProvider.error}'));
    }

    if (taskProvider.tasks.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada tugas untuk kategori ini.\nCoba ganti filter.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return RefreshIndicator(
      // REVISI: Panggil fungsi refresh dari server
      onRefresh: () => taskProvider.refreshTasksFromServer(),
      child: ListView.builder(
        itemCount: taskProvider.tasks.length,
        itemBuilder: (context, index) {
          final task = taskProvider.tasks[index];
          final uid = task['uid'] as String?;
          if (uid == null) return const SizedBox.shrink();

          final deadline = taskProvider.getDateTimeFromTask(task);
          if (deadline == null) return const SizedBox.shrink();

          final isCompleted = taskProvider.isTaskCompleted(uid);
          final isOverdue = deadline.toLocal().isBefore(DateTime.now()) && !isCompleted;
          final summary = task['summary'] as String?;
          final formattedDate = DateFormat('EEE, d MMM yyyy, HH:mm', 'id_ID').format(deadline.toLocal());

          final dynamic cats = task['categories'];
          String? category;
          if (cats is List && cats.isNotEmpty) {
            category = cats.first as String?;
          } else if (cats is String) {
            category = cats;
          }

          final customCourseName = taskProvider.courseNames[category];
          String courseDisplayString;
          if (customCourseName != null && customCourseName.isNotEmpty) {
            courseDisplayString = customCourseName;
          } else if (category != null) {
            courseDisplayString = "ID: ...${category.substring(category.length - 8)}";
          } else {
            courseDisplayString = '';
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: isOverdue ? Colors.red[50] : (isCompleted ? Colors.grey[200] : Colors.white),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailPage(task: task),
                  ),
                );
              },
              leading: Checkbox(
                value: isCompleted,
                onChanged: (bool? value) {
                  taskProvider.toggleTaskCompletion(uid);
                },
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (courseDisplayString.isNotEmpty) ...[
                    Text(
                      courseDisplayString,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red.shade700 : Colors.blue.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    summary ?? 'Tanpa Judul',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? Colors.red[800] : Colors.black87,
                      decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Deadline: $formattedDate',
                  style: TextStyle(
                    color: isOverdue ? Colors.red[700] : Colors.grey[700],
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

