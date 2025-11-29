import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whats_app_kaede/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WhatsNowApp());

    // Verify that the app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
