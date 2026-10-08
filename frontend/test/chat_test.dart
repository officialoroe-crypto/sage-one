import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/feature_workspaces.dart';
import 'package:flutter/material.dart';

class _ChatClient extends http.BaseClient {
  String? lastPath;
  @override Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastPath=request.url.path;
    final body=jsonEncode({'success':true,'session_id':'session-1','response':{'content':'Real SAGE response'}});
    return http.StreamedResponse(Stream.value(utf8.encode(body)),200,headers:{'content-type':'application/json'});
  }
}

void main() {
  testWidgets('Chat screen sends through the real chat API', (tester) async {
    final client=_ChatClient();
    final api=SageApi(client:client,baseUrl:'http://test',authToken:'token');
    await tester.pumpWidget(MaterialApp(home:ChatScreen(api:api)));
    final field=find.byType(TextField);
    await tester.enterText(field,'Hello SAGE');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();
    expect(client.lastPath,'/chat');
    expect(find.text('Hello SAGE'),findsOneWidget);
    expect(find.text('Real SAGE response'),findsOneWidget);
    api.dispose();
  });
}
