// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:document_scanner/main.dart';

void main() {
  testWidgets('Document Scanner app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DocumentScannerApp());

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that our app starts with the home screen
    expect(find.text('DigiDocs'), findsOneWidget);
    
    // The app should load successfully without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
