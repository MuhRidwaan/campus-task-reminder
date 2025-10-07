import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/task_provider.dart';

class TaskDetailPage extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskDetailPage({super.key, required this.task});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = task['summary'] as String? ?? 'Detail Tugas';
    final description = (task['description'] as String? ?? 'Tidak ada deskripsi.').replaceAll('\\n', '\n').replaceAll('\\,', ',');
    final deadline = context.read<TaskProvider>().getDateTimeFromTask(task);
    final uid = task['uid'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (uid != null)
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                final isPriority = taskProvider.isTaskPriority(uid);
                return IconButton(
                  icon: Icon(
                    isPriority ? Icons.star : Icons.star_border,
                    color: isPriority ? Colors.amber : null,
                  ),
                  tooltip: 'Tandai sebagai Prioritas',
                  onPressed: () {
                    taskProvider.toggleTaskPriority(uid);
                  },
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final deadlineText = deadline != null
                  ? DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(deadline.toLocal())
                  : 'Tidak ada deadline';
              Share.share(
                'Jangan lupa tugas:\n\n*${summary}*\nDeadline: ${deadlineText}\n\n_Powered by Campus Task Reminder_',
                subject: 'Reminder Tugas: $summary',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (deadline != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.timer_outlined, color: Colors.blue),
                  title: const Text('Deadline', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID').format(deadline.toLocal())),
                ),
              ),
            const SizedBox(height: 16),

            if (uid != null)
              Card(
                child: Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    return SwitchListTile(
                      title: const Text('Mode Studi Intensif', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Dapatkan pengingat setiap hari (19:00) untuk tugas ini.'),
                      value: taskProvider.isIntensiveStudy(uid),
                      onChanged: (bool value) {
                        taskProvider.toggleIntensiveStudy(uid);
                      },
                      secondary: const Icon(Icons.school),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            Text('Deskripsi:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),

            Linkify(
              onOpen: (link) => _launchURL(link.url),
              text: description,
              style: Theme.of(context).textTheme.bodyLarge,
              linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Buka di E-learning'),
                onPressed: () {
                  _launchURL('https://elearning.uai.ac.id/calendar/view.php');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

