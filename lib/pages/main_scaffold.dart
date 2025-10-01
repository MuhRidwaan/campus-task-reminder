import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tasks_page.dart';
import 'notes_page.dart';
import 'settings_page.dart';
import '../providers/note_provider.dart';
import '../providers/task_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'donation_page.dart';
// REVISI: Pastikan tidak ada impor yang tidak perlu

class MainScaffold extends StatefulWidget {
  final String icsUrl;
  const MainScaffold({super.key, required this.icsUrl});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadInitialData(widget.icsUrl);
      Provider.of<NoteProvider>(context, listen: false).loadNotes();
      _checkAndShowDonationPopup();
    });

    _pages = <Widget>[
      const TasksPage(),
      const NotesPage(),
      const SettingsPage(),
    ];
  }

  Future<void> _checkAndShowDonationPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final installDateString = prefs.getString('install_date');
    if (installDateString == null) {
      await prefs.setString('install_date', now.toIso8601String());
      return;
    }

    final installDate = DateTime.parse(installDateString);
    final daysSinceInstall = now.difference(installDate).inDays;

    final bool isPaydayPeriod = (now.day >= 25 && now.day <= 31) || (now.day >= 1 && now.day <= 3);

    if (daysSinceInstall >= 3 && isPaydayPeriod) {
      final periodKey = (now.day >= 25) ? 'end' : 'start';
      final popupId = 'donation_popup_${now.year}-${now.month}_$periodKey';

      final bool hasShown = prefs.getBool(popupId) ?? false;

      if (!hasShown && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gak Pernah Ke-skip Deadline Lagi kan? 😉'),
            content: const Text('Dukungan secangkir kopi darimu bakal bikin developernya makin semangat nambahin fitur-fitur baru!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nanti Aja'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DonationPage()));
                },
                child: const Text('Gas Gue Traktir'),
              ),
            ],
          ),
        );
        await prefs.setBool(popupId, true);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tugas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt),
            label: 'Catatan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

