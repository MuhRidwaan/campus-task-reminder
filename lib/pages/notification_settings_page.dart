import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _notifyH1 = true;
  bool _notifyToday = true;
  bool _notifyH2 = true;
  bool _notifyEvening = true;

  List<Map<String, dynamic>> _customReminders = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final customRemindersJson = prefs.getString('custom_reminders') ?? '[]';

    setState(() {
      _notifyH1 = prefs.getBool('notify_h1') ?? true;
      _notifyToday = prefs.getBool('notify_today') ?? true;
      _notifyH2 = prefs.getBool('notify_h2') ?? true;
      _notifyEvening = prefs.getBool('notify_evening') ?? true;
      _customReminders = (jsonDecode(customRemindersJson) as List)
          .cast<Map<String, dynamic>>();
    });
  }

  Future<void> _saveAndReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_h1', _notifyH1);
    await prefs.setBool('notify_today', _notifyToday);
    await prefs.setBool('notify_h2', _notifyH2);
    await prefs.setBool('notify_evening', _notifyEvening);
    await prefs.setString('custom_reminders', jsonEncode(_customReminders));

    final tasks = context.read<TaskProvider>().allTasks;
    await NotificationService.scheduleAllNotifications(tasks);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pengaturan notifikasi disimpan!'),
            duration: Duration(seconds: 1)),
      );
    }
  }

  void _showAddCustomReminderDialog() {
    final valueController = TextEditingController();
    final titleController = TextEditingController();
    String selectedUnit = 'menit';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Pengingat Kustom'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: 'Judul Notifikasi',
                    hintText: 'Contoh: Waktunya Mengerjakan!'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: valueController,
                      decoration: const InputDecoration(labelText: 'Waktu'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedUnit,
                    items: ['menit', 'jam', 'hari']
                        .map((unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) selectedUnit = value;
                    },
                  ),
                  const Text(' sebelum'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            TextButton(
              onPressed: () {
                final int? value = int.tryParse(valueController.text);
                if (value != null && titleController.text.isNotEmpty) {
                  setState(() {
                    _customReminders.add({
                      'value': value,
                      'unit': selectedUnit,
                      'title': titleController.text,
                    });
                  });
                  _saveAndReschedule();
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _testNotification() async {
    // REVISI: Tambahkan pesan debug print
    debugPrint('--- Mencoba menjadwalkan notifikasi tes... ---');
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '🔔 Tes Notifikasi',
      'Jika kamu melihat ini, notifikasi berfungsi dengan baik!',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
            'moodle_task_test_channel', 'Tes Notifikasi',
            channelDescription: 'Channel untuk tes notifikasi.',
            importance: Importance.max,
            priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Notifikasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildSectionTitle('Preset Pengingat'),
          SwitchListTile(
            title: const Text('H-1 (09:00)'),
            value: _notifyH1,
            onChanged: (value) => setState(() {
              _notifyH1 = value;
              _saveAndReschedule();
            }),
          ),
          SwitchListTile(
            title: const Text('Pagi Hari-H (08:00)'),
            value: _notifyToday,
            onChanged: (value) => setState(() {
              _notifyToday = value;
              _saveAndReschedule();
            }),
          ),
          SwitchListTile(
            title: const Text('2 Jam Sebelum'),
            value: _notifyH2,
            onChanged: (value) => setState(() {
              _notifyH2 = value;
              _saveAndReschedule();
            }),
          ),
          SwitchListTile(
            title: const Text('Malam Cerdas (20:00)'),
            subtitle: const Text('Untuk deadline tengah malam'),
            value: _notifyEvening,
            onChanged: (value) => setState(() {
              _notifyEvening = value;
              _saveAndReschedule();
            }),
          ),
          const Divider(height: 32),
          _buildSectionTitle('Pengingat Kustom'),
          ..._customReminders.map((reminder) {
            return ListTile(
              title: Text(reminder['title']),
              subtitle: Text(
                  '${reminder['value']} ${reminder['unit']} sebelum deadline'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _customReminders.remove(reminder);
                  });
                  _saveAndReschedule();
                },
              ),
            );
          }).toList(),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tambah Pengingat'),
              onPressed: _showAddCustomReminderDialog,
            ),
          ),
          const Divider(height: 32),
          _buildSectionTitle('Debugging'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.notification_important_outlined),
              label: const Text('Tes Notifikasi Sekarang'),
              onPressed: () {
                _testNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Notifikasi tes akan muncul dalam 5 detik...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }
}
