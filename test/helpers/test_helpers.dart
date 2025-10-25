import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a widget with MaterialApp for testing
Widget createTestWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

/// Pumps a widget and settles
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget,
) async {
  await tester.pumpWidget(createTestWidget(widget));
  await tester.pumpAndSettle();
}
