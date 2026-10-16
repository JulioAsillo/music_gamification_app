// Test básico para la app de música con gamificación

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_gamification_app/main.dart';

void main() {
  testWidgets('App inicia correctamente', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app loads with the library screen
    expect(find.text('Biblioteca'), findsOneWidget);

    // Verify that bottom navigation bar is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
