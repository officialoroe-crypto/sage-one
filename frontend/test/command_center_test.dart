import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/main.dart';

class _FakeApiClient extends http.BaseClient {
  int markAllReadRequests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path == '/notifications/read-all') {
      markAllReadRequests++;
    }
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
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump();

    expect(find.text('SAGE ONE'), findsOneWidget);
    expect(find.text('STAGE'), findsOneWidget);
    expect(find.text('EVOLUTION'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('Search + verify'), findsNothing);
    expect(find.text('Build content'), findsNothing);
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
}
