import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/command_center.dart';
import 'package:sage_one/theme/sage_theme.dart';

class _FakeCommandApi extends SageApi {
  _FakeCommandApi() : super(baseUrl: 'http://localhost:8010');

  @override
  Future<Map<String, dynamic>> workerHealth() async =>
      {'worker': {'running': true}};

  @override
  Future<Map<String, dynamic>> submitBackground(String prompt) async =>
      {'task_id': 'test-task'};

  @override
  Future<Map<String, dynamic>> task(String taskId) async => {
        'id': 'test-task',
        'status': 'completed',
        'result': {
          'summary': 'Your requested report is ready.',
          'artifacts': [
            {
              'name': 'report.pdf',
              'url': 'https://example.com/report.pdf',
              'mime_type': 'application/pdf',
            },
          ],
        },
      };
}

void main() {
  testWidgets('SAGE ONE command center renders the redesigned home',
      (tester) async {
    final api = _FakeCommandApi();
    await tester.pumpWidget(
      MaterialApp(
        theme: SageTheme.dark(),
        home: CommandCenter(api: api),
      ),
    );
    await tester.pump();

    expect(find.text('SAGE ONE'), findsOneWidget);
    expect(find.text('YOUR PERSONAL AI MENTOR'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('Tell SAGE what you want done…'), findsOneWidget);
  });

  testWidgets('completed task opens a result dialog with its file',
      (tester) async {
    final api = _FakeCommandApi();
    await tester.pumpWidget(
      MaterialApp(
        theme: SageTheme.dark(),
        home: CommandCenter(api: api),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byType(TextField),
      'Create a short report',
    );
    final executeButton = find.widgetWithText(FilledButton, 'Execute');
    await tester.tap(executeButton);
    await tester.pumpAndSettle();

    expect(find.text('Your task is complete'), findsWidgets);
    expect(find.text('Your requested report is ready.'), findsOneWidget);
    expect(find.text('report.pdf'), findsWidgets);
    expect(find.byIcon(Icons.open_in_new), findsWidgets);
  });
}
