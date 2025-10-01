import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart'; // Untuk mengakses global plugin
import '../providers/task_provider.dart'; // Untuk mengakses helper getDateTime

// Kelas ini khusus untuk mengatur semua logika notifikasi
class NotificationService {
  // Metode static agar bisa dipanggil dari mana saja
  static Future<void> scheduleAllNotifications(
      List<Map<String, dynamic>> tasks) async {
    // 1. Batalkan semua notifikasi lama untuk menghindari duplikat
    await flutterLocalNotificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    final location = tz.getLocation('Asia/Jakarta');

    // 2. Baca pengaturan notifikasi preset dari pengguna
    final bool notifyH1 = prefs.getBool('notify_h1') ?? true;
    final bool notifyToday = prefs.getBool('notify_today') ?? true;
    final bool notifyH2 = prefs.getBool('notify_h2') ?? true;
    final bool notifyEvening = prefs.getBool('notify_evening') ?? true;

    // 3. Baca pengaturan notifikasi KUSTOM dari pengguna
    final customRemindersJson = prefs.getString('custom_reminders') ?? '[]';
    final List<dynamic> customReminders = jsonDecode(customRemindersJson);

    // 4. Loop melalui setiap tugas dan jadwalkan notifikasi
    for (var task in tasks) {
      final deadlineDt = TaskProvider().getDateTimeFromTask(task);
      final uid = task['uid'] as String?;
      final summary = task['summary'] as String?;

      if (deadlineDt == null || uid == null || summary == null) continue;

      final deadline = tz.TZDateTime.from(deadlineDt, location);
      if (deadline.isBefore(tz.TZDateTime.now(location))) continue;

      final uidHash = uid.hashCode;

      // REVISI: Perbaiki cara membuat TZDateTime agar tipenya benar
      // Jadwalkan notifikasi PRESET
      if (notifyH1) {
        final h1Reminder = deadline.subtract(const Duration(days: 1));
        final h1Date = tz.TZDateTime(
            location, h1Reminder.year, h1Reminder.month, h1Reminder.day, 9, 0);
        await _schedule(uidHash + 1, 'Reminder: Besok Deadline!',
            '"$summary" dikumpulkan besok.', h1Date);
      }
      if (notifyToday) {
        final todayDate = tz.TZDateTime(
            location, deadline.year, deadline.month, deadline.day, 8, 0);
        await _schedule(uidHash + 2, 'Reminder: Hari Ini Deadline!',
            '"$summary" dikumpulkan hari ini.', todayDate);
      }
      if (notifyH2) {
        final h2HourDate = deadline.subtract(const Duration(hours: 2));
        await _schedule(uidHash + 3, 'Reminder: 2 Jam Lagi!',
            '"$summary" deadline dalam 2 jam.', h2HourDate);
      }
      if (notifyEvening && (deadline.hour >= 22 || deadline.hour <= 4)) {
        final eveningDate = tz.TZDateTime(
            location, deadline.year, deadline.month, deadline.day, 20, 0);
        await _schedule(
            uidHash + 5,
            'Jangan Begadang!',
            'Deadline "$summary" malam ini, jangan sampai ketiduran!',
            eveningDate);
      }

      // Jadwalkan notifikasi KUSTOM
      for (var i = 0; i < customReminders.length; i++) {
        final reminder = customReminders[i] as Map<String, dynamic>;
        final int value = reminder['value'];
        final String unit = reminder['unit'];
        final String title = reminder['title'];

        Duration duration;
        switch (unit) {
          case 'menit':
            duration = Duration(minutes: value);
            break;
          case 'jam':
            duration = Duration(hours: value);
            break;
          case 'hari':
            duration = Duration(days: value);
            break;
          default:
            continue;
        }

        final customDate = deadline.subtract(duration);
        // ID unik untuk notifikasi kustom, dimulai dari 100
        await _schedule(uidHash + 100 + i, title, '"$summary"', customDate);
      }

      // Jadwalkan notifikasi saat deadline habis
      await _schedule(uidHash + 999, 'DEADLINE HABIS!',
          'Waktu pengerjaan "$summary" telah berakhir.', deadline);
    }
  }

  static Future<void> _schedule(
      int id, String title, String body, tz.TZDateTime scheduledDate) async {
    if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'moodle_task_scheduled_channel',
            'Jadwal Notifikasi Tugas',
            channelDescription: 'Channel untuk notifikasi tugas terjadwal.',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}
