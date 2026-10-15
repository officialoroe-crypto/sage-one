import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/feature_workspaces.dart';

class _ChatClient extends http.BaseClient {
  _ChatClient({this.failChat = false});

  final bool failChat;
  final List<String> requests = <String>[];
  int sessionCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final key = '${request.method} ${request.url.path}';
    requests.add(key);
    var status = 200;
    dynamic payload;

    if (key == 'POST /session') {
      sessionCount++;
      payload = {
        'success': true,
        'session': {'id': 'session-$sessionCount'},
      };
    } else if (key == 'POST /chat') {
      if (failChat) {
        status = 503;
        payload = {'detail': 'SAGE could not generate a reply. Retry.'};
      } else {
        final body = jsonDecode((request as http.Request).body)
            as Map<String, dynamic>;
        final sessionId = body['session_id']?.toString() ?? 'session-1';
        payload = {
          'success': true,
          'session_id': sessionId,
          'response': {'response': 'Hello from live SAGE.'},
        };
      }
    } else if (key.startsWith('GET /session/') &&
        key.endsWith('/messages')) {
      payload = {
        'success': true,
        'messages': [
          {'role': 'user', 'content': 'Say hello'},
          {'role': 'assistant', 'content': 'Hello from live SAGE.'},
        ],
      };
    } else {
      status = 404;
      payload = {'detail': 'not found'};
    }

    return http.StreamedResponse(
      Stream.value(Uint8List.fromList(utf8.encode(jsonEncode(payload)))),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

class _DeferredChatClient extends http.BaseClient {
  final Completer<http.StreamedResponse> chatResponse =
      Completer<http.StreamedResponse>();
  final List<String> requests = <String>[];
  int sessionCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final key = '${request.method} ${request.url.path}';
    requests.add(key);
    if (key == 'POST /chat') return chatResponse.future;

    if (key == 'POST /session') {
      sessionCount++;
      return http.StreamedResponse(
        Stream.value(Uint8List.fromList(utf8.encode(jsonEncode({
          'success': true,
          'session': {'id': 'session-$sessionCount'},
        })))),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }

    return http.StreamedResponse(
      Stream.value(Uint8List.fromList(utf8.encode(jsonEncode({
        'success': true,
        'messages': <dynamic>[],
      })))),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

class _RecoverableChatClient extends http.BaseClient {
  int sessionRequests = 0;
  int historyRequests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    dynamic payload;
    var status = 200;
    if (request.method == 'POST' && request.url.path == '/session') {
      sessionRequests++;
      if (sessionRequests == 1) {
        status = 503;
        payload = {'detail': 'session temporarily unavailable'};
      } else {
        payload = {'success': true, 'session': {'id': 'session-recovered'}};
      }
    } else if (request.method == 'GET' &&
        request.url.path == '/session/session-recovered/messages') {
      historyRequests++;
      if (historyRequests == 1) {
        status = 503;
        payload = {'detail': 'history temporarily unavailable'};
      } else {
        payload = {
          'success': true,
          'messages': [
            {'role': 'assistant', 'content': 'Recovered chat history'},
          ],
        };
      }
    } else {
      status = 404;
      payload = {'detail': 'not found'};
    }
    return http.StreamedResponse(
      Stream.value(Uint8List.fromList(utf8.encode(jsonEncode(payload)))),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  testWidgets('Chat calls the live chat endpoint and displays the model reply',
      (tester) async {
    final client = _ChatClient();
    final api = SageApi(client: client, baseUrl: 'http://test', authToken: 'test-token');
    await tester.pumpWidget(MaterialApp(home: ChatScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Say hello');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();

    expect(client.requests, contains('POST /chat'));
    expect(client.requests, isNot(contains('POST /command')));
    expect(find.text('Hello from live SAGE.'), findsOneWidget);
    expect(find.text('Response received'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });

  testWidgets('Chat restores the message and reports a real API failure',
      (tester) async {
    final client = _ChatClient(failChat: true);
    final api = SageApi(client: client, baseUrl: 'http://test', authToken: 'test-token');
    await tester.pumpWidget(MaterialApp(home: ChatScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Say hello');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();

    expect(find.text('Chat failed'), findsOneWidget);
    expect(find.textContaining('SAGE could not reply.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Say hello');
    expect(client.requests, contains('POST /chat'));
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });

  testWidgets('Chat offers retry for session startup and history failures',
      (tester) async {
    final client = _RecoverableChatClient();
    final api = SageApi(client: client, baseUrl: 'http://test', authToken: 'test-token');
    await tester.pumpWidget(MaterialApp(home: ChatScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not start chat.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(client.sessionRequests, 2);
    expect(find.textContaining('Could not start chat.'), findsNothing);

    await tester.tap(find.byTooltip('Refresh chat history'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chat history could not load.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(client.historyRequests, 2);
    expect(find.text('Recovered chat history'), findsOneWidget);
    expect(find.textContaining('Chat history could not load.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });

  testWidgets('Chat ignores a pending reply after a new session starts',
      (tester) async {
    final client = _DeferredChatClient();
    final api = SageApi(client: client, baseUrl: 'http://test', authToken: 'test-token');
    await tester.pumpWidget(MaterialApp(home: ChatScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Old message');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();
    expect(client.requests, contains('POST /chat'));

    await tester.tap(find.byIcon(Icons.add_comment_outlined));
    await tester.pumpAndSettle();
    expect(client.sessionCount, 2);

    client.chatResponse.complete(http.StreamedResponse(
      Stream.value(Uint8List.fromList(utf8.encode(jsonEncode({
        'success': true,
        'session_id': 'session-1',
        'response': {'response': 'Stale reply'},
      })))),
      200,
      headers: {'content-type': 'application/json'},
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Stale reply'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });
}
