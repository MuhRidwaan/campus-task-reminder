import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundSyncPage extends StatefulWidget {
  const BackgroundSyncPage({super.key});

  @override
  State<BackgroundSyncPage> createState() => _BackgroundSyncPageState();
}

class _BackgroundSyncPageState extends State<BackgroundSyncPage> {
  bool _isSyncEnabled = false;
  int _syncFrequency = 12; // Default 12 jam

  static const syncTaskName = "fetchIcsTask";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSyncEnabled = prefs.getBool('sync_enabled') ?? false;
      _syncFrequency = prefs.getInt('sync_frequency') ?? 12;
    });
  }

  Future<void> _onSyncEnabledChanged(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_enabled', isEnabled);
    setState(() {
      _isSyncEnabled = isEnabled;
    });

    if (isEnabled) {
      // Daftarkan tugas periodik
      await Workmanager().registerPeriodicTask(
        syncTaskName,
        syncTaskName,
        frequency: Duration(hours: _syncFrequency),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi latar belakang diaktifkan.')));
    } else {
      // Batalkan tugas
      await Workmanager().cancelByUniqueName(syncTaskName);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi latar belakang dinonaktifkan.')));
    }
  }

  Future<void> _onFrequencyChanged(int? newFrequency) async {
    if (newFrequency == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sync_frequency', newFrequency);
    setState(() {
      _syncFrequency = newFrequency;
    });

    // Jika sinkronisasi sudah aktif, daftarkan ulang dengan frekuensi baru
    if (_isSyncEnabled) {
      // Batalkan yang lama dulu
      await Workmanager().cancelByUniqueName(syncTaskName);
      // Daftarkan yang baru
      await Workmanager().registerPeriodicTask(
        syncTaskName,
        syncTaskName,
        frequency: Duration(hours: newFrequency),
        constraints: Constraints(networkType: NetworkType.connected),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Frekuensi diubah ke setiap $newFrequency jam.')));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinkronisasi Latar Belakang'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Aktifkan Sinkronisasi Otomatis'),
            subtitle: const Text('Mengecek tugas baru secara periodik walau aplikasi ditutup.'),
            value: _isSyncEnabled,
            onChanged: _onSyncEnabledChanged,
          ),
          const Divider(),
          ListTile(
            title: const Text('Frekuensi Sinkronisasi'),
            enabled: _isSyncEnabled,
            trailing: DropdownButton<int>(
              value: _syncFrequency,
              items: const [
                DropdownMenuItem(value: 6, child: Text('Setiap 6 Jam')),
                DropdownMenuItem(value: 12, child: Text('Setiap 12 Jam')),
                DropdownMenuItem(value: 24, child: Text('Setiap 24 Jam')),
              ],
              onChanged: _isSyncEnabled ? _onFrequencyChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}

