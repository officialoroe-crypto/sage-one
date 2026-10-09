import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/feature_workspaces.dart';

class _MissingTaskIdClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    final dynamic payload = switch ('${request.method} $path') {
      'POST /session' => {'success': true, 'session': {'id': 'session-1'}},
      'POST /command' => {'success': true, 'status': 'queued'},
      _ => {'error': 'not found'},
    };
    final status = path == '/session' || path == '/command' ? 200 : 404;
    return http.StreamedResponse(
      Stream.value(Uint8List.fromList(utf8.encode(jsonEncode(payload)))),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  testWidgets('Chat reports a missing task ID instead of remaining stuck', (tester) async {
    final api = SageApi(
      client: _MissingTaskIdClient(),
      baseUrl: 'http://test',
      authToken: 'test-token',
    );
    await tester.pumpWidget(MaterialApp(home: ChatScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Check SAGE status');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();

    expect(find.text('Could not queue command'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });
}
