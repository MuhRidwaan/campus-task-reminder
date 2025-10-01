import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main_scaffold.dart';

class UrlInputPage extends StatefulWidget {
  const UrlInputPage({super.key});

  @override
  State<UrlInputPage> createState() => _UrlInputPageState();
}

class _UrlInputPageState extends State<UrlInputPage> {
  final _urlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

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

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScaffold(icsUrl: _urlController.text),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.calendar_month, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            // REVISI: Ganti nama aplikasi
            const Text(
              'Selamat Datang di Campus Task Reminder',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan URL Kalender ICS dari E-Learning untuk memulai.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),

            // REVISI: Tambahkan tombol tutorial
            TextButton.icon(
              icon: const Icon(Icons.help_outline, size: 16),
              label: const Text('Bagaimana cara mendapatkan URL?'),
              onPressed: () {
                _launchURL('https://drive.google.com/drive/folders/1JChg2P4gPxyAMsIvfA3jOpl5hCt4WzQi');
              },
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                  labelText: 'URL ICS',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText:
                  'https://elearning.uai.ac.id/calendar/export...'),
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

