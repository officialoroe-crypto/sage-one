import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/main.dart';

class _FakeApiClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = switch (request.url.path) {
      '/brain/routing' => jsonEncode({'provider': 'test-provider'}),
      '/worker/health' => jsonEncode({'worker': {'running': true}}),
      '/execute/background' => jsonEncode({'task_id': 'test-task'}),
      '/tasks/test-task' => jsonEncode({
          'id': 'test-task',
          'status': 'completed',
          'result': {
            'summary': 'Your requested report is ready.',
            'artifacts': [
              {
                'name': 'report.pdf',
                'url': 'HTTPS://example.com/report.pdf',
                'mime_type': 'application/pdf',
              },
            ],
          },
        }),
      _ => jsonEncode({'error': 'not found'}),
    };
    final status = request.url.path == '/brain/routing' ||
            request.url.path == '/worker/health' ||
            request.url.path == '/execute/background' ||
            request.url.path == '/tasks/test-task'
        ? 200
        : 404;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}


void main() {
  testWidgets('SAGE ONE command center renders the redesigned home',
      (tester) async {
    final api = SageApi(client: _FakeApiClient());
    await tester.pumpWidget(SageOneApp(api: api));
    await tester.pump();

    expect(find.text('SAGE ONE'), findsOneWidget);
    expect(find.text('YOUR PERSONAL AI MENTOR'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('Tell SAGE what you want done…'), findsOneWidget);
    expect(find.text('STAGE'), findsNothing);
    expect(find.text('EVOLUTION'), findsNothing);
  });

  testWidgets('completed task opens a result dialog with its file',
      (tester) async {
    final api = SageApi(client: _FakeApiClient());
    await tester.pumpWidget(SageOneApp(api: api));

    await tester.enterText(
      find.byType(TextField),
      'Create a short report',
    );
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -220),
    );
    await tester.pump();
    await tester.tap(find.text('Execute'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('Your task is complete'), findsWidgets);
    expect(find.text('Your requested report is ready.'), findsOneWidget);
    expect(find.text('report.pdf'), findsWidgets);
    expect(find.byIcon(Icons.open_in_new), findsWidgets);
  });
}
