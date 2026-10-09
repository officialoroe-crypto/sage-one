import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/memory.dart';

class _MemoryReviewClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = {
      'success': true,
      'count': 1,
      'memories': [
        {
          'id': 'learned-1',
          'profile_id': 'profile-1',
          'memory_type': 'preference',
          'content': 'Prefers concise practical answers',
          'importance': 0.7,
          'confidence': 0.8,
          'source': 'auto_learning',
          'confirmed': false,
        },
      ],
    };
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      request.method == 'GET' && request.url.path == '/identity/memory/review'
          ? 200
          : 404,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

class _MemoryReviewApi extends SageApi {
  _MemoryReviewApi() : super(baseUrl: 'http://test', authToken: 'test-token');

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
  Future<List<dynamic>> profileMemories() =>
      SynchronousFuture<List<dynamic>>([_learned]);

  @override
  Future<List<dynamic>> profileMemoryReview() =>
      SynchronousFuture<List<dynamic>>(
        confirmed ? <dynamic>[] : <dynamic>[_learned],
      );

  @override
  Future<Map<String, dynamic>> updateProfileMemory(
    String memoryId, {
    required bool confirmed,
  }) {
    this.confirmed = confirmed;
    return SynchronousFuture<Map<String, dynamic>>(
      {'success': true, 'memory': _learned},
    );
  }

  @override
  Future<Map<String, dynamic>> deleteProfileMemory(String memoryId) {
    confirmed = true;
    return SynchronousFuture<Map<String, dynamic>>(
      {'success': true, 'deleted': true},
    );
  }
}

void main() {
  test('SageApi reads the pending memory review endpoint', () async {
    final api = SageApi(
      client: _MemoryReviewClient(),
      baseUrl: 'http://test',
      authToken: 'test-token',
    );

    final result = await api.profileMemoryReview();

    expect(result, hasLength(1));
    expect((result.single as Map)['id'], 'learned-1');
    api.dispose();
  });

  testWidgets('owner can review and confirm automatically learned memories',
      (tester) async {
    final api = _MemoryReviewApi();

    await tester.pumpWidget(MaterialApp(home: MemoryScreen(api: api)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('NEEDS YOUR REVIEW'), findsOneWidget);
    expect(find.text('Prefers concise practical answers'), findsOneWidget);
    expect(find.text('Keep memory'), findsOneWidget);

    await tester.tap(find.text('Keep memory'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('NEEDS YOUR REVIEW'), findsNothing);
    expect(find.text('Confirmed'), findsOneWidget);
    api.dispose();
  });
}
