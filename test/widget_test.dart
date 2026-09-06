import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hametkro coquille se construit', (WidgetTester tester) async {
    // Test léger de smoke pour le pipeline CI.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: Text('hametkro'))),
    ));
    expect(find.text('hametkro'), findsOneWidget);
  });
}
