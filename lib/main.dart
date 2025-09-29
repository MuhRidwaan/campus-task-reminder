import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- Konfigurasi Notifikasi ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Fungsi utama yang akan dieksekusi saat aplikasi dimulai
Future<void> main() async {
  // Pastikan semua binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // Atur locale untuk format tanggal Indonesia (cukup sekali di sini)
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi timezone database
  tzdata
      .initializeTimeZones(); // FIX: Menggunakan nama fungsi yang benar (Z besar)
  // Set lokasi default ke Asia/Jakarta
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  // Konfigurasi settings untuk notifikasi di Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Konfigurasi settings untuk notifikasi di iOS
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  // Gabungkan settings untuk inisialisasi
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  // Inisialisasi plugin notifikasi
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MoodleTaskApp());
}

class MoodleTaskApp extends StatelessWidget {
  const MoodleTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moodle Task Notifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Widget ini bertugas untuk mengecek apakah URL ICS sudah tersimpan atau belum
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<String?> _getIcsUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ics_url');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getIcsUrl(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          // Jika URL sudah ada, tampilkan halaman daftar tugas
          return TaskListPage(icsUrl: snapshot.data!);
        } else {
          // Jika URL belum ada, tampilkan halaman input URL
          return const UrlInputPage();
        }
      },
    );
  }
}

// Halaman untuk memasukkan URL ICS dari Moodle
class UrlInputPage extends StatefulWidget {
  const UrlInputPage({super.key});

  @override
  State<UrlInputPage> createState() => _UrlInputPageState();
}

class _UrlInputPageState extends State<UrlInputPage> {
  final _urlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveUrl() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_urlController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('URL tidak boleh kosong!')),
      );
      return;
    }

    if (!Uri.parse(_urlController.text).isAbsolute) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('URL tidak valid!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ics_url', _urlController.text);

      // Navigasi ke halaman utama dan hapus halaman ini dari stack
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TaskListPage(icsUrl: _urlController.text),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Kalender Moodle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Masukkan URL Kalender ICS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // FIX: Menghapus `const` karena `Colors.grey[600]` bukan constant.
            Text(
              'Anda bisa mendapatkan URL ini dari Moodle di bagian Kalender -> Ekspor Kalender.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                  labelText: 'URL ICS',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText:
                      'https://elearning.uai.ac.id/calendar/export_execute.php?...'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveUrl,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan & Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }
}

// Halaman utama yang menampilkan daftar tugas
class TaskListPage extends StatefulWidget {
  final String icsUrl;
  const TaskListPage({super.key, required this.icsUrl});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  // FIX: Fungsi helper untuk mendapatkan DateTime secara aman
  DateTime? _getDateTimeFromTask(Map<String, dynamic> task) {
    final dynamic dtValue = task['dtstart'];
    if (dtValue is IcsDateTime) {
      final dtString = dtValue.dt;
      // The .dt property is a string, so we need to parse it into a DateTime object.
      // Using tryParse is safer because it returns null if the string is not a valid date format.
      if (dtString is String) {
        return DateTime.tryParse(dtString);
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  // Fungsi untuk mengambil dan mem-parsing data ICS
  Future<void> _refreshTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(widget.icsUrl));
      if (response.statusCode == 200) {
        final iCalendar = ICalendar.fromString(response.body);
        final List<Map<String, dynamic>> newTasks = iCalendar.data;

        // Urutkan tugas berdasarkan tanggal mulai (deadline) dan tangani nilai null
        newTasks.sort((a, b) {
          // FIX: Menggunakan fungsi helper untuk tipe data yang aman
          final DateTime aDate = _getDateTimeFromTask(a) ?? DateTime(0);
          final DateTime bDate = _getDateTimeFromTask(b) ?? DateTime(0);
          return aDate.compareTo(bDate);
        });

        // Cek tugas baru atau deadline berubah dan kirim notifikasi
        await _checkForUpdatesAndNotify(_tasks, newTasks);

        if (mounted) {
          setState(() {
            _tasks = newTasks;
          });
          // Jadwalkan notifikasi untuk semua tugas yang diambil
          await _scheduleAllNotifications(newTasks);
        }
      } else {
        throw Exception('Gagal memuat kalender');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Logika Notifikasi ---

  Future<void> _showNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'moodle_task_channel', // ID channel
      'Notifikasi Tugas Moodle', // Nama channel
      channelDescription: 'Channel untuk notifikasi tugas dari Moodle',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true, // Mainkan suara notifikasi
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        id, title, body, platformChannelSpecifics);
  }

  Future<void> _scheduleNotification(
      int id, String title, String body, tz.TZDateTime scheduledDate) async {
    // Hanya jadwalkan jika waktu notifikasi di masa depan
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

  Future<void> _checkForUpdatesAndNotify(List<Map<String, dynamic>> oldTasks,
      List<Map<String, dynamic>> newTasks) async {
    final oldTasksMap = {for (var task in oldTasks) task['uid']: task};

    for (var newTask in newTasks) {
      final newUid = newTask['uid'] as String?;
      // FIX: Menggunakan fungsi helper untuk tipe data yang aman
      final DateTime? newDtStart = _getDateTimeFromTask(newTask);

      // Lewati jika event tidak punya UID atau deadline
      if (newUid == null || newDtStart == null) continue;

      // Cek apakah ada UID yang sama di daftar lama
      if (oldTasksMap.containsKey(newUid)) {
        final oldTask = oldTasksMap[newUid]!;
        // FIX: Menggunakan fungsi helper untuk tipe data yang aman
        final DateTime? oldDtStart = _getDateTimeFromTask(oldTask);

        // Bandingkan DTSTART (deadline)
        if (oldDtStart?.toIso8601String() != newDtStart.toIso8601String()) {
          final formattedDate =
              DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(newDtStart);
          await _showNotification(
            newUid.hashCode + 1000, // ID unik
            'Deadline Berubah!',
            '${newTask['summary']} -> $formattedDate',
          );
        }
      } else {
        // Jika tidak ada, berarti ini tugas baru
        await _showNotification(
          newUid.hashCode, // ID unik
          'Tugas Baru Ditambahkan!',
          '${newTask['summary']}',
        );
      }
    }
  }

  Future<void> _scheduleAllNotifications(
      List<Map<String, dynamic>> tasks) async {
    // Batalkan semua notifikasi yang ada untuk menghindari duplikat
    await flutterLocalNotificationsPlugin.cancelAll();

    final location = tz.getLocation('Asia/Jakarta');

    for (var task in tasks) {
      // FIX: Menggunakan fungsi helper untuk tipe data yang aman
      final DateTime? deadlineDt = _getDateTimeFromTask(task);
      final uid = task['uid'] as String?;
      final summary = task['summary'] as String?;

      // Lewati jika tidak ada deadline, uid, atau summary
      if (deadlineDt == null || uid == null || summary == null) continue;

      final deadline = tz.TZDateTime.from(deadlineDt, location);
      final now = tz.TZDateTime.now(location);

      // Jika deadline sudah lewat, jangan jadwalkan notifikasi
      if (deadline.isBefore(now)) continue;

      // UID unik untuk setiap notifikasi
      final uidHash = uid.hashCode;

      // 1. Reminder H-1 (sehari sebelum deadline jam 09:00)
      final h1Reminder = deadline.subtract(const Duration(days: 1));
      final h1Date = tz.TZDateTime(
          location, h1Reminder.year, h1Reminder.month, h1Reminder.day, 9, 0);
      await _scheduleNotification(
        uidHash + 1,
        'Reminder Tugas: Besok Deadline!',
        'Jangan lupa, "$summary" dikumpulkan besok.',
        h1Date,
      );

      // 2. Reminder Pagi (di hari H jam 08:00)
      final todayReminder = tz.TZDateTime(
          location, deadline.year, deadline.month, deadline.day, 8, 0);
      await _scheduleNotification(
        uidHash + 2,
        'Reminder Tugas: Hari Ini Deadline!',
        '"$summary" harus dikumpulkan hari ini.',
        todayReminder,
      );

      // 3. Reminder H-2 Jam (2 jam sebelum deadline)
      final h2HourReminder = deadline.subtract(const Duration(hours: 2));
      await _scheduleNotification(
        uidHash + 3,
        'Reminder: 2 Jam Lagi!',
        '"$summary" akan deadline dalam 2 jam.',
        h2HourReminder,
      );

      // 4. Notifikasi saat deadline lewat
      await _scheduleNotification(
        uidHash + 4,
        'DEADLINE HABIS!',
        'Waktu pengerjaan untuk "$summary" telah berakhir.',
        deadline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
            tooltip: 'Muat Ulang',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('ics_url');
              await flutterLocalNotificationsPlugin
                  .cancelAll(); // Hapus notifikasi terjadwal

              if (mounted) {
                navigator.pushReplacement(MaterialPageRoute(
                    builder: (context) => const UrlInputPage()));
              }
            },
            tooltip: 'Ganti URL',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada tugas ditemukan.\nCoba muat ulang.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshTasks,
                  child: ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      // FIX: Menggunakan fungsi helper untuk tipe data yang aman
                      final DateTime? deadline = _getDateTimeFromTask(task);

                      // Jika event tidak punya deadline, jangan tampilkan
                      if (deadline == null) {
                        return const SizedBox.shrink();
                      }

                      final isOverdue = deadline.isBefore(DateTime.now());

                      // Format tanggal dengan intl
                      final formattedDate =
                          DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID')
                              .format(deadline.toLocal());
                      final summary = task['summary'] as String?;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        color: isOverdue ? Colors.red[50] : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          title: Text(
                            summary ?? 'Tanpa Judul',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  isOverdue ? Colors.red[800] : Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Deadline: $formattedDate',
                              style: TextStyle(
                                  color: isOverdue
                                      ? Colors.red[700]
                                      : Colors.grey[700]),
                            ),
                          ),
                          trailing: isOverdue
                              ? const Text(
                                  'Lewat',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
