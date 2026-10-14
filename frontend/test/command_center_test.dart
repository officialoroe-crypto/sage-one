import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/main.dart';
import 'package:sage_one/screens/command_center.dart';

class _FakeApiClient extends http.BaseClient {
  int markAllReadRequests = 0;
  int commandRequests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path == '/execute/background') commandRequests++;
    if (request.url.path == '/notifications/read-all') {
      markAllReadRequests++;
    }
    final body = switch (request.url.path) {
      '/brain/routing' => jsonEncode({'provider': 'test-provider'}),
      '/execute/background' => jsonEncode({'task_id': 'test-task'}),
      '/tasks/test-task' => jsonEncode({'id': 'test-task', 'status': 'completed', 'result': 'Command complete'}),
      _ => jsonEncode({'error': 'not found'}),
    };
    final status = request.url.path == '/brain/routing' ||
            (request.url.path == '/execute/background' || request.url.path == '/tasks/test-task')
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
  testWidgets('SAGE ONE app shell renders after splash', (tester) async {
    final api = SageApi(client: _FakeApiClient());
    await tester.pumpWidget(SageOneApp(api: api));
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump();

    expect(find.text('SAGE ONE'), findsOneWidget);
    expect(find.text('STAGE'), findsOneWidget);
    expect(find.text('EVOLUTION'), findsOneWidget);
    expect(find.text('Search + verify'), findsNothing);
    expect(find.text('Build content'), findsNothing);
  });

  testWidgets('Execute button queues a command through the backend', (tester) async {
    final client = _FakeApiClient();
    final api = SageApi(
      client: client,
      baseUrl: 'http://test',
      authToken: 'test-token',
    );
    await tester.pumpWidget(MaterialApp(home: CommandCenter(api: api)));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Run a safe test command');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Run a safe test command',
    );
    final executeButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Execute'),
    );
    expect(executeButton.onPressed, isNotNull);
    executeButton.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(client.commandRequests, 1);
    expect(find.text('Command complete'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });

  testWidgets('opening Tasks does not mark notifications read', (tester) async {
    final client = _FakeApiClient();
    final api = SageApi(client: client);
    await tester.pumpWidget(SageOneApp(api: api));
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump();

    await tester.tap(find.text('Tasks'));
    await tester.pump();

    expect(client.markAllReadRequests, 0);
  });

  testWidgets('Voice command captures a transcript and waits for explicit confirmation', (tester) async {
    final client = _FakeApiClient();
    final api = SageApi(
      client: client,
      baseUrl: 'http://test',
      authToken: 'test-token',
    );
    await tester.pumpWidget(MaterialApp(home: CommandCenter(api: api)));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('VOICE COMMAND  ·  TAP TO SPEAK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('SAGE VOICE'), findsOneWidget);
    expect(find.text('CONFIRM & EXECUTE'), findsOneWidget);
    expect(client.commandRequests, 0);

    await tester.enterText(find.byType(TextField).last, 'Run a safe test command');
    await tester.pump();
    expect(client.commandRequests, 0, reason: 'Editing a transcript must not execute it.');

    await tester.tap(find.text('CONFIRM & EXECUTE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(client.commandRequests, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });

}
