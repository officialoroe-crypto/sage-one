import 'package:flutter_test/flutter_test.dart';

import 'package:sage_one/main.dart';

void main() {
  testWidgets('SAGE ONE command center renders', (tester) async {
    await tester.pumpWidget(const SageOneApp());
    expect(find.text('SAGE ONE'), findsOneWidget);
    expect(find.text('COMMAND CENTER'), findsOneWidget);
    expect(find.text('What are we building today?'), findsOneWidget);
    expect(find.text('Research'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
  });
}
