import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_one/screens/feature_workspaces.dart';

void main() {
  testWidgets('workspace action does not falsely report success', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AppsScreen(),
    ));

    await tester.tap(find.text('Browse connected apps'));
    await tester.pumpAndSettle();

    expect(find.text('Integration status'), findsOneWidget);
    expect(find.text('Interface available • Live actions not connected yet'), findsOneWidget);
    expect(find.textContaining('not connected to a live workflow yet'), findsOneWidget);
    expect(find.text('is ready in SAGE ONE.'), findsNothing);
  });
}
