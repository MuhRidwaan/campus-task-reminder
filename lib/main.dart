import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uai_notify/providers/note_provider.dart';
import 'package:uai_notify/providers/theme_provider.dart';
import 'package:uai_notify/services/notification_service.dart';
import 'package:workmanager/workmanager.dart';

import 'pages/main_scaffold.dart';
import 'pages/url_input_page.dart';
import 'providers/task_provider.dart';

// --- Global Objects ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  debugPrint('notification payload: ${notificationResponse.payload}');
}

const AndroidNotificationChannel scheduledChannel = AndroidNotificationChannel(
  'moodle_task_scheduled_channel', 'Jadwal Notifikasi Tugas',
  description: 'Channel untuk notifikasi tugas terjadwal.',
  importance: Importance.max, playSound: true,
);

const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
  'moodle_task_test_channel', 'Tes Notifikasi',
  description: 'Channel untuk tes notifikasi.',
  importance: Importance.max, playSound: true,
);

// REVISI: Fungsi callback untuk Workmanager (harus top-level)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Inisialisasi service yang dibutuhkan di dalam background isolate
      await _initializeDependencies();

      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString('ics_url');
      final lastCache = prefs.getString('task_cache');

      if (url == null || url.isEmpty) {
        return Future.value(true); // Tidak ada URL, hentikan
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Bandingkan data baru dengan cache
        if (response.body != lastCache) {
          await prefs.setString('task_cache', response.body);

          // Gunakan TaskProvider secara lokal untuk parsing dan menjadwalkan notif
          final taskProvider = TaskProvider();
          taskProvider.parseAndSetTasks(response.body);

          await flutterLocalNotificationsPlugin.show(
              -99,
              'Tugas Diperbarui!',
              'Ada tugas baru atau perubahan jadwal, cek sekarang!',
              NotificationDetails(android: scheduledChannel.toAndroidNotificationDetails())
          );
        }
      }
      return Future.value(true);
    } catch (e) {
      debugPrint("Error in background task: $e");
      return Future.value(false); // Gagal
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeDependencies();

  // REVISI: Inisialisasi Workmanager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  final prefs = await SharedPreferences.getInstance();
  final icsUrl = prefs.getString('ics_url');

  runApp(MoodleTaskApp(initialUrl: icsUrl));
}

// ... sisa kode main.dart ...
Future<void> _initializeDependencies() async {
  await initializeDateFormatting('id_ID', null);

  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
  DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (androidImplementation != null) {
    await androidImplementation.createNotificationChannel(scheduledChannel);
    await androidImplementation.createNotificationChannel(testChannel);
    await androidImplementation.requestNotificationsPermission();
  }
}

class MoodleTaskApp extends StatelessWidget {
  final String? initialUrl;
  const MoodleTaskApp({super.key, this.initialUrl});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Campus Task Reminder',
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: Colors.blue,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.blue,
            ),
            themeMode: themeProvider.themeMode,
            home:
            initialUrl != null && initialUrl!.isNotEmpty
                ? MainScaffold(icsUrl: initialUrl!)
                : const UrlInputPage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

extension on AndroidNotificationChannel {
  AndroidNotificationDetails toAndroidNotificationDetails() {
    return AndroidNotificationDetails(
      id,
      name,
      channelDescription: description,
      importance: importance,
      playSound: playSound,
    );
  }
}

