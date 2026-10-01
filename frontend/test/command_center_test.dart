import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/main.dart';

class _FakeApiClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = switch (request.url.path) {
      '/brain/routing' => jsonEncode({'provider': 'test-provider'}),
      '/execute/background' => jsonEncode({'task_id': 'test-task'}),
      '/tasks/test-task' => jsonEncode({
          'status': 'completed',
          'result': {'content': 'Your report is ready.'},
        }),
      _ => jsonEncode({'error': 'not found'}),
    };
    final status = request.url.path == '/brain/routing' ||
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
  testWidgets('SAGE Command Centre renders the standalone orb experience',
      (tester) async {
    final api = SageApi(client: _FakeApiClient());
    await tester.pumpWidget(SageOneApp(api: api));
    await tester.pump();

    expect(find.text('SAGE ONE'), findsOneWidget);
    expect(find.text('What would you like me to do?'), findsOneWidget);
    expect(find.text('Send to SAGE'), findsOneWidget);
    expect(find.text('COMMAND CENTER'), findsNothing);
    expect(find.text('RESEARCH'), findsNothing);
  });

  testWidgets('completed task displays a clickable result preview',
      (tester) async {
    final api = SageApi(client: _FakeApiClient());
    await tester.pumpWidget(SageOneApp(api: api));
    await tester.enterText(find.byType(TextField), 'Create a report');
    await tester.tap(find.text('Send to SAGE'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Your task is complete'), findsOneWidget);
    expect(find.text('View completed result'), findsOneWidget);

    await tester.tap(find.text('View completed result'));
    await tester.pumpAndSettle();
    expect(find.text('Your report is ready.'), findsOneWidget);
  });
}
