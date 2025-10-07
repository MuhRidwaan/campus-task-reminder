import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';
import '../providers/task_provider.dart';

class NotificationService {

  static Future<void> scheduleAllNotifications(List<Map<String, dynamic>> tasks, Map<String, String> courseNames, Set<String> priorityUids, Set<String> intensiveStudyUids) async {
    await flutterLocalNotificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    final location = tz.getLocation('Asia/Jakarta');

    final bool notifyH1 = prefs.getBool('notify_h1') ?? true;
    final bool notifyToday = prefs.getBool('notify_today') ?? true;
    final bool notifyH2 = prefs.getBool('notify_h2') ?? true;
    final bool notifyEvening = prefs.getBool('notify_evening') ?? true;
    final customReminders = jsonDecode(prefs.getString('custom_reminders') ?? '[]') as List;
    final dailyReminders = jsonDecode(prefs.getString('daily_reminders') ?? '[]') as List;

    for (var task in tasks) {
      final deadlineDt = TaskProvider().getDateTimeFromTask(task);
      final uid = task['uid'] as String?;
      final summary = task['summary'] as String?;

      if (deadlineDt == null || uid == null || summary == null) continue;

      final deadline = tz.TZDateTime.from(deadlineDt, location);
      if (deadline.isBefore(tz.TZDateTime.now(location))) continue;

      final uidHash = uid.hashCode;
      final dynamic cats = task['categories'];
      String? category;
      if (cats is List && cats.isNotEmpty) {
        category = cats.first as String?;
      } else if (cats is String) {
        category = cats;
      }
      final courseName = courseNames[category] ?? 'Tugas';

      final bool isPriority = priorityUids.contains(uid);
      final priorityPrefix = isPriority ? '🔥 ' : '';

      if (notifyH1) {
        final h1Date = tz.TZDateTime(location, deadline.year, deadline.month, deadline.day - 1, 9, 0);
        await _schedule(uidHash + 1, '$priorityPrefix[$courseName] Reminder: Besok Deadline!', '"$summary" dikumpulkan besok.', h1Date);
      }
      if (notifyToday) {
        final todayDate = tz.TZDateTime(location, deadline.year, deadline.month, deadline.day, 8, 0);
        await _schedule(uidHash + 2, '$priorityPrefix[$courseName] Reminder: Hari Ini Deadline!', '"$summary" dikumpulkan hari ini.', todayDate);
      }
      if (notifyH2) {
        final h2HourDate = deadline.subtract(const Duration(hours: 2));
        await _schedule(uidHash + 3, '$priorityPrefix[$courseName] Reminder: 2 Jam Lagi!', '"$summary" deadline dalam 2 jam.', h2HourDate);
      }
      if (notifyEvening && (deadline.hour >= 22 || deadline.hour <= 4)) {
        final eveningDate = tz.TZDateTime(location, deadline.year, deadline.month, deadline.day, 20, 0);
        await _schedule(uidHash + 5, '$priorityPrefix[$courseName] Jangan Begadang!', 'Deadline "$summary" malam ini, jangan sampai ketiduran!', eveningDate);
      }

      for (var i = 0; i < customReminders.length; i++) {
        final reminder = customReminders[i] as Map<String, dynamic>;
        final int value = reminder['value'];
        final String unit = reminder['unit'];
        final String title = reminder['title'];
        Duration duration;
        switch (unit) {
          case 'menit': duration = Duration(minutes: value); break;
          case 'jam': duration = Duration(hours: value); break;
          case 'hari': duration = Duration(days: value); break;
          default: continue;
        }
        final customDate = deadline.subtract(duration);
        await _schedule(uidHash + 100 + i, '$priorityPrefix[$courseName] $title', '"$summary"', customDate);
      }

      for (var i = 0; i < dailyReminders.length; i++) {
        final reminder = dailyReminders[i] as Map<String, dynamic>;
        final String title = reminder['title'];
        final List<int> days = (reminder['days'] as List).cast<int>();
        final timeParts = (reminder['time'] as String).split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        tz.TZDateTime now = tz.TZDateTime.now(location);
        tz.TZDateTime checkDate = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
        if (checkDate.isBefore(now)) {
          checkDate = checkDate.add(const Duration(days: 1));
        }
        int dayCounter = 0;
        while (checkDate.isBefore(deadline)) {
          if (days.contains(checkDate.weekday)) {
            await _schedule(uidHash + 200 + (i * 100) + dayCounter, '$priorityPrefix[$courseName] $title', '"$summary"', checkDate);
            dayCounter++;
          }
          checkDate = checkDate.add(const Duration(days: 1));
        }
      }

      if (intensiveStudyUids.contains(uid)) {
        tz.TZDateTime now = tz.TZDateTime.now(location);
        tz.TZDateTime checkDate = tz.TZDateTime(location, now.year, now.month, now.day, 19, 0);
        if (checkDate.isBefore(now)) checkDate = checkDate.add(const Duration(days: 1));
        int dayCounter = 0;
        while (checkDate.isBefore(deadline)) {
          await _schedule(uidHash + 300 + dayCounter, '$priorityPrefix[$courseName] 💡 Waktunya Cicil Tugas!', '"$summary"', checkDate);
          checkDate = checkDate.add(const Duration(days: 1));
          dayCounter++;
        }
      }

      if (isPriority) {
        final h6Date = deadline.subtract(const Duration(hours: 6));
        await _schedule(uidHash + 6, '$priorityPrefix[$courseName] 6 JAM LAGI!', 'Tugas penting "$summary" segera deadline!', h6Date);
        final m30Date = deadline.subtract(const Duration(minutes: 30));
        await _schedule(uidHash + 7, '$priorityPrefix[$courseName] 30 MENIT LAGI!', 'SEGERA KUMPULKAN: "$summary"!', m30Date);
      }

      await _schedule(uidHash + 999, 'DEADLINE HABIS!', 'Waktu pengerjaan "$summary" telah berakhir.', deadline, addActions: false);
    }
  }

  static Future<void> _schedule(int id, String title, String body, tz.TZDateTime scheduledDate, {bool addActions = true}) async {
    if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      final payload = jsonEncode({ 'id': id, 'title': title, 'body': body });
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id, title, body, scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'moodle_task_scheduled_channel', 'Jadwal Notifikasi Tugas',
            channelDescription: 'Channel untuk notifikasi tugas terjadwal.',
            importance: Importance.max, priority: Priority.high, playSound: true,
            actions: addActions ? [
              const AndroidNotificationAction('snooze_10m', 'Tunda 10 Menit'),
              const AndroidNotificationAction('snooze_1h', 'Tunda 1 Jam'),
            ] : null,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
  }
}

