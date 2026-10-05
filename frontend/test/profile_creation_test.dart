import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/screens/profile_creation.dart';

void main() {
  testWidgets('validates and returns the profile foundation', (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(MaterialApp(home: ProfileCreationScreen(onComplete: (value) => result = value)));
    expect(find.text('CREATE YOUR PROFILE'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter your name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'SAGE User');
    await tester.enterText(find.byType(TextFormField).at(1), '9800000000');
    await tester.enterText(find.byType(TextFormField).at(2), 'Kathmandu');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(result?['name'], 'SAGE User');
    expect(result?['location'], 'Kathmandu');
  });
}
