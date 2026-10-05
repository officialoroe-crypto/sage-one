import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/research.dart';

class _ResearchClient extends SageApi {
  _ResearchClient():super(baseUrl:'http://localhost:8010');
}
void main() {
  testWidgets('research screen exposes a real research workflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResearchScreen(api: _ResearchClient()),
      ),
    );
    expect(find.text('RESEARCH OS'), findsOneWidget);
    expect(find.text('Turn a question into evidence.'), findsOneWidget);
    expect(find.text('What should Sage research?'), findsOneWidget);
    expect(find.text('RESEARCH HISTORY'), findsOneWidget);
  });
}
