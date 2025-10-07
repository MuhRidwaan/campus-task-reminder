import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// REVISI: Menggunakan impor absolut untuk konsistensi
import 'package:uai_notify/main.dart';
import 'package:uai_notify/providers/task_provider.dart';
import 'package:uai_notify/services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _notifyH1 = true;
  bool _notifyToday = true;
  bool _notifyH2 = true;
  bool _notifyEvening = true;
  List<Map<String, dynamic>> _customReminders = [];
  List<Map<String, dynamic>> _dailyReminders = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final customRemindersJson = prefs.getString('custom_reminders') ?? '[]';
      final dailyRemindersJson = prefs.getString('daily_reminders') ?? '[]';
      setState(() {
        _notifyH1 = prefs.getBool('notify_h1') ?? true;
        _notifyToday = prefs.getBool('notify_today') ?? true;
        _notifyH2 = prefs.getBool('notify_h2') ?? true;
        _notifyEvening = prefs.getBool('notify_evening') ?? true;
        _customReminders = (jsonDecode(customRemindersJson) as List).cast<Map<String, dynamic>>();
        _dailyReminders = (jsonDecode(dailyRemindersJson) as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() {
        _customReminders = [];
        _dailyReminders = [];
      });
    }
  }

  Future<void> _saveAndReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_h1', _notifyH1);
    await prefs.setBool('notify_today', _notifyToday);
    await prefs.setBool('notify_h2', _notifyH2);
    await prefs.setBool('notify_evening', _notifyEvening);
    await prefs.setString('custom_reminders', jsonEncode(_customReminders));
    await prefs.setString('daily_reminders', jsonEncode(_dailyReminders));

    final taskProvider = context.read<TaskProvider>();
    final tasks = taskProvider.allTasks;
    final courseNames = taskProvider.courseNames;
    final priorityUids = taskProvider.priorityTaskUids;
    final intensiveStudyUids = taskProvider.intensiveStudyUids;
    await NotificationService.scheduleAllNotifications(tasks, courseNames, priorityUids, intensiveStudyUids);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan notifikasi disimpan!'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Input Tidak Valid'), content: Text(message), actions: [TextButton(child: const Text('Mengerti'), onPressed: () => Navigator.of(ctx).pop())]));
  }

  void _showAddCustomReminderDialog() {
    final valueController = TextEditingController();
    final titleController = TextEditingController();
    String selectedUnit = 'menit';
    showDialog(context: context, builder: (context) {
      return AlertDialog(title: const Text('Tambah Pengingat Kustom'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Judul Notifikasi', hintText: 'Contoh: Waktunya Mengerjakan!')), Row(children: [Expanded(child: TextField(controller: valueController, decoration: const InputDecoration(labelText: 'Waktu'), keyboardType: TextInputType.number)), const SizedBox(width: 8), DropdownButton<String>(value: selectedUnit, items: ['menit', 'jam', 'hari'].map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(), onChanged: (value) {if (value != null) selectedUnit = value;}), const Text(' sebelum')])]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), TextButton(onPressed: () {final int? value = int.tryParse(valueController.text); if (titleController.text.trim().isEmpty) {_showErrorDialog('Judul notifikasi tidak boleh kosong.'); return;} if (value == null) {_showErrorDialog('Waktu harus diisi dengan angka.'); return;} setState(() {_customReminders.add({'value': value, 'unit': selectedUnit, 'title': titleController.text});}); _saveAndReschedule(); Navigator.pop(context);}, child: const Text('Simpan'))]);
    },
    );
  }

  void _showAddDailyReminderDialog() {
    final titleController = TextEditingController(text: "Waktunya Belajar!");
    TimeOfDay selectedTime = TimeOfDay.now();
    List<int> selectedDays = [1, 2, 3, 4, 5];
    final dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(title: const Text('Pengingat Harian'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Judul Notifikasi')), const SizedBox(height: 16), ListTile(title: const Text('Waktu Pengingat'), subtitle: Text(selectedTime.format(context)), trailing: const Icon(Icons.edit_outlined), onTap: () async {final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime); if (picked != null) {setDialogState(() {selectedTime = picked;});}}), const SizedBox(height: 16), const Text('Ulangi setiap hari:'), Wrap(spacing: 6.0, children: List<Widget>.generate(7, (int index) {return FilterChip(label: Text(dayLabels[index]), selected: selectedDays.contains(index + 1), onSelected: (bool selected) {setDialogState(() {if (selected) {selectedDays.add(index + 1);} else {selectedDays.removeWhere((day) => day == index + 1);}});});}))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), TextButton(onPressed: () {if (titleController.text.trim().isEmpty) {_showErrorDialog('Judul notifikasi tidak boleh kosong.'); return;} if (selectedDays.isEmpty) {_showErrorDialog('Pilih setidaknya satu hari untuk pengingat.'); return;} setState(() {_dailyReminders.add({'title': titleController.text, 'time': '${selectedTime.hour}:${selectedTime.minute}', 'days': selectedDays});}); _saveAndReschedule(); Navigator.pop(context);}, child: const Text('Simpan'))]);
      },
      );
    },
    );
  }

  Future<void> _testNotification() async {
    const title = '🔔 Tes Notifikasi';
    const body = 'Jika kamu melihat ini, notifikasi berfungsi dengan baik!';
    final payload = jsonEncode({'id': -1, 'title': title, 'body': body});
    await flutterLocalNotificationsPlugin.zonedSchedule(-1, title, body, tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)), const NotificationDetails(android: AndroidNotificationDetails('moodle_task_test_channel', 'Tes Notifikasi', channelDescription: 'Channel untuk tes notifikasi.', importance: Importance.max, priority: Priority.high, actions: [AndroidNotificationAction('snooze_10m', 'Tunda 10 Menit'), AndroidNotificationAction('snooze_1h', 'Tunda 1 Jam')])), androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, payload: payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Notifikasi')),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          Card(
            child: Column(children: [
              const ListTile(leading: Icon(Icons.timer_outlined), title: Text('Preset Pengingat', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Pengingat umum yang direkomendasikan.')),
              SwitchListTile(title: const Text('H-1 (09:00)'), value: _notifyH1, onChanged: (value) => setState(() { _notifyH1 = value; _saveAndReschedule(); })),
              SwitchListTile(title: const Text('Pagi Hari-H (08:00)'), value: _notifyToday, onChanged: (value) => setState(() { _notifyToday = value; _saveAndReschedule(); })),
              SwitchListTile(title: const Text('2 Jam Sebelum'), value: _notifyH2, onChanged: (value) => setState(() { _notifyH2 = value; _saveAndReschedule(); })),
              SwitchListTile(title: const Text('Malam Cerdas (20:00)'), subtitle: const Text('Untuk deadline tengah malam'), value: _notifyEvening, onChanged: (value) => setState(() { _notifyEvening = value; _saveAndReschedule(); })),
            ]),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(children: [
              const ListTile(leading: Icon(Icons.add_alert_outlined), title: Text('Pengingat Kustom (Sekali Jalan)', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Atur pengingat satu kali sebelum deadline.')),
              ..._customReminders.map((reminder) => ListTile(leading: const Icon(Icons.label_important_outline, size: 20), title: Text(reminder['title']), subtitle: Text('${reminder['value']} ${reminder['unit']} sebelum deadline'), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {setState(() => _customReminders.remove(reminder)); _saveAndReschedule();}))).toList(),
              Padding(padding: const EdgeInsets.all(8.0), child: TextButton.icon(icon: const Icon(Icons.add), label: const Text('Tambah Pengingat Kustom'), onPressed: _showAddCustomReminderDialog)),
            ]),
          ),
          const SizedBox(height: 16),
          Card(
              child: Column(children: [
                const ListTile(leading: Icon(Icons.alarm_on_outlined), title: Text('Pengingat Belajar Global (Harian)', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Alarm harian yang berlaku untuk semua tugas.')),
                ..._dailyReminders.map((reminder) {final days = (reminder['days'] as List).cast<int>()..sort(); final dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']; final dayString = days.map((d) => dayLabels[d-1]).join(', '); return ListTile(leading: const Icon(Icons.label_important_outline, size: 20), title: Text(reminder['title']), subtitle: Text('Setiap ${dayString} - Pukul ${reminder['time']}'), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {setState(() => _dailyReminders.remove(reminder)); _saveAndReschedule();}));}).toList(),
                Padding(padding: const EdgeInsets.all(8.0), child: TextButton.icon(icon: const Icon(Icons.alarm_add), label: const Text('Tambah Pengingat Global'), onPressed: _showAddDailyReminderDialog)),
              ])
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.amber[50],
            child: Padding(padding: const EdgeInsets.all(8.0), child: Column(children: [
              ListTile(leading: Icon(Icons.bug_report_outlined, color: Colors.amber[800]), title: Text('Debugging', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900]))),
              ElevatedButton.icon(icon: const Icon(Icons.notification_important_outlined), label: const Text('Tes Notifikasi Sekarang'), onPressed: () {_testNotification(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi tes akan muncul dalam 5 detik...')));}),
            ])),
          ),
        ],
      ),
    );
  }
}

