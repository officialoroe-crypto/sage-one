import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/world_intelligence.dart';

class _WorldClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    dynamic body;
    switch (request.url.path) {
      case '/world/status':
        body = {
          'success': true,
          'learning_enabled': true,
          'self_modification': false,
          'default_topics': ['AI', 'Business', 'Education'],
        };
      case '/world/knowledge':
        body = {
          'success': true,
          'knowledge': [
            {
              'topic': 'AI',
              'title': 'Verified update',
              'source_count': 3,
              'updated_at': '2026-10-08',
            }
          ],
        };
      case '/world/due':
        body = {'success': true, 'topics': ['AI']};
      default:
        body = {'success': true};
    }
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(body)));
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

SageApi _api() => SageApi(
      client: _WorldClient(),
      baseUrl: 'http://test',
      authToken: 'test-token',
    );

void main() {
  testWidgets('World Intelligence renders verified world state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SageTheme.dark(),
        home: WorldIntelligenceScreen(api: _api()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WORLD INTELLIGENCE'), findsOneWidget);
    expect(find.text('SAGE WORLD LAYER'), findsOneWidget);
    expect(find.text('Verified update'), findsOneWidget);
    expect(find.text('3 sources'), findsOneWidget);
    expect(find.text('AI'), findsWidgets);
    expect(find.text('ON'), findsNWidgets(3));
  });
}
