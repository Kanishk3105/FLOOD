import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flodo_app/main.dart';

void main() {
  testWidgets('Task list shell loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Tasks'), findsOneWidget);
  });
}
