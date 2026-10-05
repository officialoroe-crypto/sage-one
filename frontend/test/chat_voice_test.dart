import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/chat.dart';
import 'package:sage_one/screens/voice_listening.dart';

class _FakeClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final ok = request.url.path == '/chat';
    final body = ok
        ? jsonEncode({
            'success': true,
            'session_id': 'session-1',
            'response': {'message': 'Hello from SAGE Core.'},
          })
        : jsonEncode({'error': 'not found'});
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      ok ? 200 : 404,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  testWidgets('chat sends through the SAGE chat endpoint', (tester) async {
    final api = SageApi(client: _FakeClient(), baseUrl: 'http://localhost:8010');
    await tester.pumpWidget(MaterialApp(home: ChatScreen(api: api)));
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Hello from SAGE Core.'), findsOneWidget);
  });

  testWidgets('voice listening surface renders explicit controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VoiceListeningScreen()));
    expect(find.text('Start listening'), findsOneWidget);
    expect(find.text('Your words will appear here.'), findsOneWidget);
  });
}
