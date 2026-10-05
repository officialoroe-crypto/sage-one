import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/chat.dart';

class _ChatClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request.url.path == '/chat'
        ? jsonEncode({
            'success': true,
            'session_id': 'session-1',
            'response': {'message': 'Hello from the real SAGE chat contract.'},
          })
        : jsonEncode({'error': 'not found'});
    final status = request.url.path == '/chat' ? 200 : 404;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  testWidgets('chat sends through SAGE Core and keeps the session',
      (tester) async {
    final api = SageApi(client: _ChatClient(), baseUrl: 'http://localhost:8010');
    await tester.pumpWidget(MaterialApp(home: ChatScreen(api: api)));

    await tester.enterText(find.byType(TextField), 'Hello SAGE');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Hello SAGE'), findsOneWidget);
    expect(find.text('Hello from the real SAGE chat contract.'), findsOneWidget);
  });
}
