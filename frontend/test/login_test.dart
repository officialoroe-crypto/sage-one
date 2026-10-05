import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../lib/core/identity_client.dart';
import '../lib/screens/login.dart';

class _ConfigClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = jsonEncode({'developer_mode': false, 'google_client_id': 'test.apps.googleusercontent.com'});
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      request: request,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  testWidgets('renders cinematic SAGE authentication surface', (tester) async {
    final identity = IdentityClient(client: _ConfigClient(), baseUrl: 'https://example.test');

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          identity: identity,
          onSignedIn: (_) {},
        ),
      ),
    );

    await tester.pump();

    expect(find.text('S A G E   O N E'), findsOneWidget);
    expect(find.text('YOUR AI. YOUR EDGE.'), findsOneWidget);
    expect(find.text('Enter SAGE ONE'), findsOneWidget);
    expect(find.text('SECURE ACCESS'), findsOneWidget);
    expect(find.text('PRIVATE BY DESIGN'), findsOneWidget);
  });
}
