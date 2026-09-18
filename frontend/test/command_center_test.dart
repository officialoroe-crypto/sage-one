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
      _ => jsonEncode({'error': 'not found'}),
    };
    final status = request.url.path == '/brain/routing' ||
            request.url.path == '/execute/background'
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
  testWidgets('SAGE ONE command center renders', (tester) async {
    final api = SageApi(client: _FakeApiClient());
    await tester.pumpWidget(SageOneApp(api: api));
    await tester.pump();

    expect(find.text('SAGE ONE'), findsOneWidget);
    expect(find.text('COMMAND CENTER'), findsOneWidget);
    expect(find.text('What are we building today?'), findsOneWidget);
    expect(find.text('Search, read, cross-check'), findsOneWidget);
    expect(find.text('Queued and running work'), findsOneWidget);
  });
}
