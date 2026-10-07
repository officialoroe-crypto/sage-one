import 'dart:convert';

import 'package:flutter/material.dart';
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

class _FakeChatApi extends SageApi {
  _FakeChatApi() : super(client: _FakeClient(), baseUrl: 'http://localhost:8010');

  @override
  Future<Map<String, dynamic>> chat({
    required String message,
    String? sessionId,
    String? goal,
    String? task,
    String? project,
    Map<String, dynamic>? context,
  }) async {
    return {
      'success': true,
      'session_id': 'session-1',
      'response': {'message': 'Hello from SAGE Core.'},
    };
  }
}

void main() {
  testWidgets('chat renders the returned SAGE response', (tester) async {
    final api = _FakeChatApi();
    expect(api.chatResponseText({'message': 'Hello from SAGE Core.'}), 'Hello from SAGE Core.');
    await tester.pumpWidget(MaterialApp(home: ChatScreen(api: api)));
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Hello from SAGE Core.'), findsOneWidget);
  });

  testWidgets('voice listening surface renders explicit controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VoiceListeningScreen()));
    expect(find.text('Start listening'), findsOneWidget);
    expect(find.text('Your words will appear here.'), findsOneWidget);
  });
}
