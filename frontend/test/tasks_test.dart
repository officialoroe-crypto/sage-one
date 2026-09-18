import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/tasks.dart';

class _TasksApiClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = switch (request.url.path) {
      '/tasks' => jsonEncode({
          'tasks': [
            {
              'id': 'task-123',
              'title': 'Research: Flutter reliability',
              'status': 'running',
            },
          ],
        }),
      '/tasks/task-123' => jsonEncode({
          'id': 'task-123',
          'title': 'Research: Flutter reliability',
          'status': 'completed',
          'created_at': '2026-09-18T10:00:00Z',
          'updated_at': '2026-09-18T10:01:00Z',
          'result': 'Research completed.',
        }),
      _ => jsonEncode({'detail': 'not found'}),
    };
    final status = request.url.path == '/tasks' ||
            request.url.path == '/tasks/task-123'
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
  testWidgets('Tasks screen renders durable task and opens detail',
      (tester) async {
    final api = SageApi(client: _TasksApiClient());
    await tester.pumpWidget(
      MaterialApp(home: TasksScreen(api: api)),
    );
    await tester.pump();

    expect(find.text('Execution queue'), findsOneWidget);
    expect(find.text('Research: Flutter reliability'), findsOneWidget);
    expect(find.text('running • task-123'), findsOneWidget);

    await tester.tap(find.text('Research: Flutter reliability'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('STATUS  •  completed'), findsOneWidget);
    expect(find.text('Task ID'), findsOneWidget);
    expect(find.text('Research completed.'), findsOneWidget);
  });
}
