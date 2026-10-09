import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/sales.dart';

class _SalesClient extends http.BaseClient {
  final List<String> requestPaths = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestPaths.add(request.url.path);
    dynamic body;
    if (request.url.path == '/sales/leads') {
      body = {'success': true, 'leads': [{
        'id': 'lead-1', 'business_name': 'Demo Hardware', 'website': 'https://example.com',
        'score': 42, 'tier': 'hot', 'status': 'outreach_pending',
        'audit_json': jsonEncode({'gaps': ['clear_cta']}),
        'outreach_json': jsonEncode({'draft': 'Demo outreach', 'requires_approval': true}),
      }]};
    } else if (request.url.path == '/sales/leads/lead-1') {
      body = {'success': true, 'lead': {
        'id': 'lead-1', 'business_name': 'Demo Hardware', 'website': 'https://example.com',
        'score': 42, 'tier': 'hot', 'status': 'outreach_pending',
        'audit_json': jsonEncode({'gaps': ['clear_cta']}),
        'outreach_json': jsonEncode({'draft': 'Demo outreach', 'requires_approval': true}),
      }};
    } else if (request.url.path == '/sales/leads/lead-1/history') {
      body = {'success': true, 'history': [{'event_type': 'discovered_audited_scored', 'status': 'completed', 'created_at': '2026-10-09T00:00:00Z'}]};
    } else {
      body = {'success': true};
    }
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(body)));
    return http.StreamedResponse(Stream.value(bytes), 200, headers: {'content-type': 'application/json'});
  }
}

SageApi _api() => SageApi(client: _SalesClient(), baseUrl: 'http://test', authToken: 'test');

void main() {
  testWidgets('sales pipeline renders a lead and opens its detail', (tester) async {
    final client = _SalesClient();
    final api = SageApi(client: client, baseUrl: 'http://test', authToken: 'test');
    await tester.pumpWidget(MaterialApp(home: SalesScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Lead pipeline'), findsOneWidget);
    expect(find.text('Demo Hardware'), findsOneWidget);
    await tester.tap(find.text('Demo Hardware'));
    await tester.pumpAndSettle();
    expect(find.text('Outreach draft'), findsOneWidget);
    expect(find.text('Approve outreach'), findsOneWidget);
    expect(find.text('Record follow-up'), findsOneWidget);
    expect(find.text('Activity history'), findsOneWidget);

    await tester.tap(find.text('Record follow-up'));
    await tester.pumpAndSettle();
    expect(find.text('What happened / next step'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Approve outreach'));
    await tester.pumpAndSettle();
    expect(client.requestPaths, contains('/sales/leads/lead-1/approve-outreach'));
  });
}
