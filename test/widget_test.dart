import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senior_care_app/main.dart';

void main() {
  testWidgets('App loads and shows loader', (WidgetTester tester) async {
    await tester.pumpWidget(const SeniorCareApp());

    // App should load MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);

    // Initially shows loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}