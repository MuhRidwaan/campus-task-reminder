import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label berhasil disalin!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dukung Developer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.coffee_rounded, size: 80, color: Colors.brown[400]),
            const SizedBox(height: 16),
            const Text(
              '☕ Traktir kopi developer biar makin semangat!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Setiap dukungan, sekecil apapun, sangat berarti untuk pengembangan aplikasi ini kedepannya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            _buildSectionTitle('E-Wallet (a.n. M Ridwan)'),
            _buildDonationOption(
              context: context,
              asset: 'assets/dana_logo.png', // Placeholder, ganti jika punya logo
              title: 'Salin No. DANA',
              subtitle: '089503412994',
              onTap: () => _copyToClipboard(context, '089503412994', 'No. DANA'),
            ),
            _buildDonationOption(
              context: context,
              asset: 'assets/gopay_logo.png', // Placeholder
              title: 'Salin No. GoPay',
              subtitle: '089503412994',
              onTap: () => _copyToClipboard(context, '089503412994', 'No. GoPay'),
            ),
            _buildDonationOption(
              context: context,
              asset: 'assets/shopeepay_logo.png', // Placeholder
              title: 'Salin No. ShopeePay',
              subtitle: '089503412994',
              onTap: () => _copyToClipboard(context, '089503412994', 'No. ShopeePay'),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Transfer Bank'),
            _buildDonationOption(
              context: context,
              asset: 'assets/bca_logo.png', // Placeholder
              title: 'Salin No. Rekening BCA',
              subtitle: '1970738203 (a.n. M Ridwan)',
              onTap: () => _copyToClipboard(context, '1970738203', 'No. Rekening BCA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildDonationOption({
    required BuildContext context,
    String? asset, // Untuk path logo
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        // leading: asset != null
        //   ? Image.asset(asset, width: 40, height: 40)
        //   : Icon(Icons.copy, color: Theme.of(context).primaryColor),
        leading: Icon(Icons.copy, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

