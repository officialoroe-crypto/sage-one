import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/research.dart';

class _ResearchApiClient extends http.BaseClient {
  int polls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = switch (request.url.path) {
      '/execute/background' => jsonEncode({'task_id': 'research-1'}),
      '/tasks/research-1' => jsonEncode({
          'id': 'research-1',
          'status': polls++ == 0 ? 'running' : 'completed',
          'result': 'Evidence report ready.',
        }),
      _ => jsonEncode({'detail': 'not found'}),
    };
    final status = request.url.path == '/execute/background' ||
            request.url.path == '/tasks/research-1'
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
  testWidgets('Research screen queues and displays task result', (tester) async {
    final client = _ResearchApiClient();
    final api = SageApi(client: client, authToken: 'test-token');
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ResearchScreen(api: api))),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Flutter reliability');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();

    expect(find.text('Research in progress'), findsOneWidget);
    expect(find.text('TASK  research-1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(find.text('Research complete'), findsOneWidget);
    expect(find.text('Evidence report ready.'), findsOneWidget);
  });
}
