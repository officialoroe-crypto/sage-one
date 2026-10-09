import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/final_surfaces.dart';

class _FinalSurfaceClient extends http.BaseClient {
  int markAllReadRequests = 0;
  int profilePatchRequests = 0;
  int profileGetRequests = 0;
  int markReadRequests = 0;
  bool failProfileLoad = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    if (path == '/notifications/read-all') markAllReadRequests++;
    if (path == '/notifications/notice-1/read') markReadRequests++;
    if (path == '/identity/me' && request.method == 'PATCH') profilePatchRequests++;
    if (path == '/identity/me' && request.method == 'GET') profileGetRequests++;
    var status = 200;
    dynamic body = <String, dynamic>{'success': true};

    if (path == '/economy/me') {
      body = {
        'success': true,
        'spark': {'balance': 125, 'lifetime_earned': 200, 'lifetime_spent': 75},
        'ledger': [
          {'reason': 'Test grant', 'delta': 125, 'created_at': '2026-10-08T00:00:00Z'}
        ],
        'evolution': {
          'lifetime_achievement': 250,
          'tier': 'Silver',
          'stage': 'LOW',
          'progress': {
            'current_threshold': 0,
            'next_threshold': 1000,
            'next_tier': 'Silver',
            'ratio': 0.25
          }
        }
      };
    } else if (path == '/economy/evolution/tiers') {
      body = {
        'success': true,
        'tiers': [
          {'tier': 'Bronze', 'threshold': 0, 'order': 1},
          {'tier': 'Silver', 'threshold': 1000, 'order': 2}
        ]
      };
    } else if (path == '/identity/me' && request.method == 'GET') {
      if (failProfileLoad) {
        status = 503;
        body = {'detail': 'profile service unavailable'};
      } else {
        body = {
          'success': true,
          'profile': {
            'id': 'profile-1',
            'name': 'SAGE User',
            'help_intent': 'Build SAGE',
            'basic_info': {
              'saved_preference': 'keep-this',
              'settings': {'notifications': true, 'compact_mode': false}
            }
          }
        };
      }
    } else if (path == '/notifications') {
      body = {'success': true, 'notifications': [
        {'id': 'notice-1', 'title': 'Task completed', 'message': 'Task completed', 'created_at': '2026-10-08T00:00:00Z'}
      ]};
    } else if (path == '/economy/payment/status') {
      body = {
        'success': true,
        'configured': false,
        'provider': null,
        'mode': 'not_configured',
        'can_create_payment': false,
        'message': 'Payment provider is not configured; no payment action is available.'
      };
    } else if (path == '/tasks') {
      body = {'success': true, 'tasks': []};
    } else if (path == '/workflow/workspaces') {
      body = {'success': true, 'workspaces': []};
    }

    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(body)));
    return http.StreamedResponse(
      Stream.value(bytes),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

SageApi _api() => SageApi(
  client: _FinalSurfaceClient(),
  baseUrl: 'http://test',
  authToken: 'test-token',
);

void main() {
  testWidgets('final economy, profile, settings, notification and payment surfaces render', (tester) async {
    final screens = <Widget>[
      SparkWalletScreen(api: _api()),
      TransactionsScreen(api: _api()),
      ProfileFinalScreen(api: _api()),
      SettingsFinalScreen(api: _api()),
      NotificationsFinalScreen(api: _api()),
      PaymentFinalScreen(api: _api()),
      FileManagerFinalScreen(api: _api()),
      AiStudioFinalScreen(api: _api()),
    ];

    final labels = <String>[
      'Spark Wallet',
      'Transactions',
      'Profile',
      'Settings',
      'Activity',
      'Provider readiness',
      'Task artifacts',
      'Workflow Studio',
    ];

    for (var i = 0; i < screens.length; i++) {
      await tester.pumpWidget(MaterialApp(home: screens[i]));
      await tester.pumpAndSettle();
      expect(find.text(labels[i]), findsOneWidget);
    }
  });
  testWidgets('Profile validates required fields before sending an update', (tester) async {
    final client = _FinalSurfaceClient();
    final api = SageApi(
      client: client,
      baseUrl: 'http://test',
      authToken: 'test-token',
    );
    await tester.pumpWidget(MaterialApp(home: ProfileFinalScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(client.profilePatchRequests, 0);
    expect(find.text('Enter your address.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '12 Demo Road');
    await tester.pump();
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(client.profilePatchRequests, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });

  testWidgets('AI Studio workspace dialog validates input and cancels safely', (tester) async {
    final api = _api();
    await tester.pumpWidget(MaterialApp(home: AiStudioFinalScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Workspace'));
    await tester.pumpAndSettle();
    expect(find.text('Create workspace'), findsOneWidget);

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create'),
    );
    expect(createButton.onPressed, isNull);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Demo workspace');
    await tester.enterText(fields.at(1), 'demo-workspace');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Create')).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });

  testWidgets(
    'Settings cannot overwrite a profile when loading fails and can retry',
    (tester) async {
      final client = _FinalSurfaceClient()..failProfileLoad = true;
      final api = SageApi(
        client: client,
        baseUrl: 'http://test',
        authToken: 'test-token',
      );
      await tester.pumpWidget(MaterialApp(home: SettingsFinalScreen(api: api)));
      await tester.pumpAndSettle();

      expect(find.text('Settings could not be loaded'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(client.profilePatchRequests, 0);
      expect(
        tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save settings'),
        ).onPressed,
        isNull,
      );

      client.failProfileLoad = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(client.profileGetRequests, 2);
      expect(
        tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save settings'),
        ).onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();

      expect(client.profilePatchRequests, 1);
      expect(find.text('Settings saved.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      api.dispose();
    },
  );

  testWidgets('Settings save persists updated preferences', (tester) async {
    final client = _FinalSurfaceClient();
    final api = SageApi(
      client: client,
      baseUrl: 'http://test',
      authToken: 'test-token',
    );
    await tester.pumpWidget(MaterialApp(home: SettingsFinalScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile).at(1));
    await tester.pump();
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();

    expect(client.profilePatchRequests, 1);
    expect(find.text('Settings saved.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });

  testWidgets('Notification read button calls the backend', (tester) async {
    final client = _FinalSurfaceClient();
    final api = SageApi(
      client: client,
      baseUrl: 'http://test',
      authToken: 'test-token',
    );
    await tester.pumpWidget(MaterialApp(home: NotificationsFinalScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.done));
    await tester.pumpAndSettle();

    expect(client.markReadRequests, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });

  testWidgets('Notifications mark-all-read button calls the backend', (tester) async {
    final client = _FinalSurfaceClient();
    final api = SageApi(
      client: client,
      baseUrl: 'http://test',
      authToken: 'test-token',
    );
    await tester.pumpWidget(MaterialApp(home: NotificationsFinalScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(client.markAllReadRequests, 1);
  });

}
