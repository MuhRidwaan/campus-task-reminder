import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uai_notify/main.dart';
import 'package:uai_notify/pages/url_input_page.dart';

void main() {
  testWidgets('App starts with UrlInputPage when no URL is saved',
      (WidgetTester tester) async {
    // REVISI: Bangun aplikasi dengan initialUrl null untuk mensimulasikan
    // kondisi pertama kali dijalankan.
    await tester.pumpWidget(const MoodleTaskApp(initialUrl: null));

    // Tunggu widget selesai di-render
    await tester.pumpAndSettle();

    // Verifikasi bahwa halaman input URL yang ditampilkan
    expect(find.byType(UrlInputPage), findsOneWidget);

    // Verifikasi ada teks sambutan
    expect(find.text('Selamat Datang di UAI Notify'), findsOneWidget);
  });
}
