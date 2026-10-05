import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_one/screens/first_run_welcome.dart';

void main() {
  testWidgets('first-run welcome moves through setup and completes', (tester) async {
    Set<String>? selected;
    await tester.pumpWidget(MaterialApp(
      home: FirstRunWelcomeScreen(onComplete: (value) => selected = value),
    ));
    expect(find.text('WELCOME TO SAGE ONE'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('WHAT SHOULD SAGE HELP WITH?'), findsOneWidget);
    await tester.tap(find.text('Research'));
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('YOU ARE READY'), findsOneWidget);
    await tester.tap(find.text('ENTER SAGE ONE'));
    await tester.pumpAndSettle();
    expect(selected, contains('Research'));
  });
}
