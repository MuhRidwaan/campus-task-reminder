import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import 'about_page.dart';
import 'background_sync_page.dart';
import 'course_settings_page.dart';
import 'donation_page.dart';
import 'notification_settings_page.dart';
import 'profile_page.dart';
import 'url_input_page.dart';
import '../providers/task_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // REVISI: Fungsi baru untuk konfirmasi hapus cache
  void _showClearCacheConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Cache?'),
          content: const Text(
              'Ini akan menghapus semua data tersimpan (URL, cache tugas, pengaturan) dan memulai ulang aplikasi. Gunakan ini jika aplikasi mengalami masalah.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Ya, Hapus'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Hapus semua data

                Navigator.of(dialogContext).pop(); // Tutup dialog
                // Kembali ke halaman input URL, hapus semua halaman sebelumnya
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const UrlInputPage()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    // ... (kode logout tetap sama)
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dan mengganti URL ICS?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Ya, Keluar'),
              onPressed: () async {
                // Untuk logout, cukup hapus URL saja
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('ics_url');

                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const UrlInputPage()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showNotificationHelpDialog(BuildContext context) {
    // ... (kode bantuan notifikasi tetap sama)
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Panduan Notifikasi'),
          content: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: const <TextSpan>[
                  TextSpan(text: 'Jika notifikasi tidak muncul, terutama di HP Xiaomi, Oppo, Vivo, atau sejenisnya, ikuti checklist ini:\n\n'),
                  TextSpan(text: '1. Izinkan Notifikasi\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'Pastikan notifikasi untuk aplikasi ini sudah diizinkan di pengaturan HP.\n\n'),
                  TextSpan(text: '2. Aktifkan Autostart\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'Buka Pengaturan > Aplikasi > Cari "Campus Task Reminder" > Aktifkan "Autostart" atau "Mulai Otomatis".\n\n'),
                  TextSpan(text: '3. Atur Baterai\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'Di halaman info aplikasi yang sama, masuk ke "Penghemat Baterai" > Pilih "Tanpa Pembatasan".\n\n'),
                  TextSpan(text: '4. KUNCI APLIKASI (Langkah Final)\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  TextSpan(text: 'Ini adalah langkah paling penting. Buka layar "Recent Apps" (yang menampilkan semua aplikasi berjalan), cari aplikasi kita, lalu tekan dan tahan hingga muncul menu, kemudian pilih ikon "Gembok" atau "Lock".\n\nLangkah ini akan mencegah sistem mematikan aplikasi di latar belakang.'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pengaturan'),
          ),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profil Mahasiswa'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.brightness_6_outlined),
                title: const Text('Mode Gelap'),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.setTheme(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.sync_outlined),
                title: const Text('Sinkronisasi Latar Belakang'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BackgroundSyncPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Pengaturan Notifikasi'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Atur Nama Mata Kuliah'),
                onTap: () {
                  final categories = context.read<TaskProvider>().uniqueCategories;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CourseSettingsPage(courseCategories: categories.toList())));
                },
              ),
              ListTile(
                leading: Icon(Icons.help_outline, color: Colors.amber[800]),
                title: const Text('Bantuan Notifikasi'),
                subtitle: const Text('Jika notifikasi tidak muncul/telat'),
                onTap: () => _showNotificationHelpDialog(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.coffee),
                title: const Text('Traktir Kopi Developer'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DonationPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Tentang Aplikasi'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()));
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red[700]),
                title: Text('Logout & Ganti URL', style: TextStyle(color: Colors.red[700])),
                onTap: () => _showLogoutConfirmation(context),
              ),
              // REVISI: Tambahkan menu untuk hapus cache
              ListTile(
                leading: Icon(Icons.delete_sweep_outlined, color: Colors.red[700]),
                title: Text('Hapus Cache & Mulai Ulang', style: TextStyle(color: Colors.red[700])),
                onTap: () => _showClearCacheConfirmation(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

