import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/memory.dart';

class _MemoryReviewClient extends http.BaseClient {
  bool confirmed = false;

  Map<String, dynamic> get _learned => {
        'id': 'learned-1',
        'profile_id': 'profile-1',
        'memory_type': 'preference',
        'content': 'Prefers concise practical answers',
        'importance': 0.7,
        'confidence': 0.8,
        'source': 'auto_learning',
        'confirmed': confirmed,
      };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    dynamic body;
    final path = request.url.path;
    if (request.method == 'GET' && path == '/identity/memory') {
      body = {'success': true, 'memories': [_learned]};
    } else if (request.method == 'GET' && path == '/identity/memory/review') {
      body = {'success': true, 'memories': confirmed ? [] : [_learned], 'count': confirmed ? 0 : 1};
    } else if (request.method == 'PATCH' && path == '/identity/memory/learned-1') {
      confirmed = true;
      body = {'success': true, 'memory': _learned};
    } else if (request.method == 'DELETE' && path == '/identity/memory/learned-1') {
      confirmed = true;
      body = {'success': true, 'deleted': true};
    } else {
      body = {'detail': 'not found'};
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      request.method == 'GET' && path.startsWith('/identity/memory') ||
              request.method == 'PATCH' ||
              request.method == 'DELETE'
          ? 200
          : 404,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  testWidgets('owner can review and confirm automatically learned memories',
      (tester) async {
    final client = _MemoryReviewClient();
    final api = SageApi(
      client: client,
      baseUrl: 'http://test',
      authToken: 'test-token',
    );

    final directReview = await api.profileMemoryReview();
    expect(directReview, hasLength(1));

    await tester.pumpWidget(MaterialApp(home: MemoryScreen(api: api)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(
      find.text('NEEDS YOUR REVIEW'),
      findsOneWidget,
      reason: 'Current text nodes: ${tester.widgetList<Text>(find.byType(Text)).map((item) => item.data).toList()}',
    );
    expect(find.text('Prefers concise practical answers'), findsOneWidget);
    expect(find.text('Keep memory'), findsOneWidget);

    await tester.tap(find.text('Keep memory'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('NEEDS YOUR REVIEW'), findsNothing);
    expect(find.text('Confirmed'), findsOneWidget);
  });
}
