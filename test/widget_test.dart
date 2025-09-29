// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uai_notify/main.dart';

void main() {
  testWidgets('Renders UrlInputPage when no URL is saved',
      (WidgetTester tester) async {
    // Set up a mock for SharedPreferences to return null (no saved URL).
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MoodleTaskApp());

    // Wait for the FutureBuilder in AuthWrapper to complete.
    await tester.pumpAndSettle();

    // Verify that the UrlInputPage is displayed.
    expect(find.text('Setup Kalender Moodle'), findsOneWidget);
    expect(find.text('Masukkan URL Kalender ICS'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
