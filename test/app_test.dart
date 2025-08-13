import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gocab/main.dart';

void main() {
  group('GoCab App Tests', () {
    testWidgets('App should start without crashing', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that the app starts without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Should show loading initially due to Firebase', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      // Should show loading indicator when Firebase is initializing
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
