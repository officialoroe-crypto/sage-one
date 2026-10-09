import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/create.dart';
import 'package:sage_one/screens/economy.dart';
import 'package:sage_one/screens/evolution.dart';
import 'package:sage_one/screens/owner_console.dart';
import 'package:sage_one/screens/project_detail.dart';
import 'package:sage_one/screens/projects.dart';
import 'package:sage_one/screens/world_intelligence.dart';

class _ScreenSmokeClient extends http.BaseClient {
  int worldRefreshRequests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    if (path == '/world/refresh' && request.method == 'POST') worldRefreshRequests++;
    final dynamic body = switch (path) {
      '/workflow/workspaces' => {'success': true, 'workspaces': []},
      '/economy/me' => {
          'success': true,
          'spark': {'balance': 100, 'lifetime_earned': 100, 'lifetime_spent': 0},
          'ledger': [],
          'evolution': {
            'tier': 'Bronze',
            'stage': 'LOW',
            'lifetime_achievement': 0,
            'progress': {
              'ratio': 0.0,
              'current_threshold': 0,
              'next_threshold': 100,
              'next_tier': 'Silver',
            },
          },
        },
      '/economy/costs' => {'success': true, 'costs': []},
      '/economy/evolution/tiers' => {
          'success': true,
          'tiers': [
            {'tier': 'Bronze', 'threshold': 0, 'order': 1},
            {'tier': 'Silver', 'threshold': 100, 'order': 2},
          ],
        },
      '/economy/owner/status' => {'success': true, 'owner_mode': true, 'god_mode': true},
      '/economy/owner/audit' => {'success': true, 'events': []},
      '/workflow/workspaces/workspace-1/projects' => {'success': true, 'projects': []},
      '/workflow/projects/project-1/assets' => {'success': true, 'assets': []},
      '/workflow/projects/project-1/relations' => {'success': true, 'relations': []},
      '/workflow/projects/project-1/workflows' => {'success': true, 'workflows': []},
      '/world/status' => {'success': true, 'status': 'ready'},
      '/world/knowledge' => {'success': true, 'knowledge': []},
      '/world/due' => {'success': true, 'topics': []},
      _ => {'success': true, 'items': []},
    };
    return http.StreamedResponse(
      Stream.value(Uint8List.fromList(utf8.encode(jsonEncode(body)))),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

SageApi _api() => SageApi(
  client: _ScreenSmokeClient(),
  baseUrl: 'http://test',
  authToken: 'test-token',
);

void main() {
  testWidgets('Create screen renders against the backend contract', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CreateScreen(api: _api())));
    await tester.pumpAndSettle();
    expect(find.text('CREATE'), findsOneWidget);
  });

  testWidgets('Economy screen renders balance and cost state', (tester) async {
    await tester.pumpWidget(MaterialApp(home: EconomyScreen(api: _api())));
    await tester.pumpAndSettle();
    expect(find.text('SAGE Spark'), findsWidgets);
    expect(find.text('Premium work • Evolution protected'), findsOneWidget);
  });

  testWidgets('Evolution screen renders canonical tier catalog', (tester) async {
    await tester.pumpWidget(MaterialApp(home: EvolutionScreen(api: _api())));
    await tester.pumpAndSettle();
    expect(find.text('Evolution'), findsOneWidget);
    expect(find.text('THE EVOLUTION PATH'), findsOneWidget);
  });

  testWidgets('Owner Console renders status and audit state', (tester) async {
    await tester.pumpWidget(MaterialApp(home: OwnerConsoleScreen(api: _api())));
    await tester.pumpAndSettle();
    expect(find.text('SAGE Owner Console'), findsOneWidget);
    expect(find.text('SET SPARK'), findsOneWidget);
  });

  testWidgets('Project detail loads assets, relations and workflows', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ProjectDetailScreen(
        api: _api(),
        project: {
          'id': 'project-1',
          'workspace_id': 'workspace-1',
          'name': 'Smoke Test Project',
          'project_type': 'general',
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Smoke Test Project'), findsOneWidget);
    expect(find.text('ASSET GRAPH'), findsOneWidget);

    await tester.tap(find.byTooltip('Add asset'));
    await tester.pumpAndSettle();
    expect(find.text('Add workflow asset'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Run SAGE command'));
    await tester.pumpAndSettle();
    expect(find.text('Run SAGE in this project'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('World refresh button sends the refresh request', (tester) async {
    final client = _ScreenSmokeClient();
    final api = SageApi(
      client: client,
      baseUrl: 'http://test',
      authToken: 'test-token',
    );
    await tester.pumpWidget(MaterialApp(home: WorldIntelligenceScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Refresh world knowledge'));
    await tester.pumpAndSettle();

    expect(client.worldRefreshRequests, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });

  testWidgets('Projects screen renders the empty workspace state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ProjectsScreen(api: _api(), onProjectTap: (_) {}),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Projects'), findsOneWidget);
  });

  testWidgets('World Intelligence loads status, knowledge and due topics', (tester) async {
    await tester.pumpWidget(MaterialApp(home: WorldIntelligenceScreen(api: _api())));
    await tester.pumpAndSettle();
    expect(find.text('World Intelligence'), findsOneWidget);
  });
}
