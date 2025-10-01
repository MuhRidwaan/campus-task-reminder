import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
      ),
      // REVISI: Menggunakan ListView untuk layout yang lebih terstruktur
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- KARTU PROFIL DEVELOPER ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Muhammad Ridwan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'App Developer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- JUDUL UNTUK SOSIAL MEDIA ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Hubungi Saya',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // --- KARTU LINK SOSIAL MEDIA ---
          Card(
            child: Column(
              children: [
                _buildSocialLink(
                  context: context,
                  icon: Icons.code,
                  title: 'GitHub',
                  url: 'https://github.com/MuhRidwaan',
                ),
                _buildSocialLink(
                  context: context,
                  icon: Icons.camera_alt_outlined,
                  title: 'Instagram',
                  url: 'https://www.instagram.com/muhridwaan_/',
                ),
                _buildSocialLink(
                  context: context,
                  icon: Icons.work_outline,
                  title: 'LinkedIn',
                  url: 'https://www.linkedin.com/in/muhammad-ridwan-8aa23726a/',
                  showDivider: false, // Tidak perlu divider di item terakhir
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- INFORMASI APLIKASI ---
          Center(
            child: Column(
              children: [
                const Text(
                  'Campus Task Reminder',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Versi 2.1.0',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dibuat dengan ❤️ menggunakan Flutter',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Helper widget untuk membuat ListTile sosial media agar tidak berulang
  Widget _buildSocialLink({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String url,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _launchURL(url),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

