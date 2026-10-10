import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sage_one/core/sage_api.dart';
import 'package:sage_one/screens/feature_workspaces.dart';

class _JobsClient extends http.BaseClient {
  final List<String> requests = <String>[];
  final List<Map<String, dynamic>> postedJobs = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> applications = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> applicationUpdates = <Map<String, dynamic>>[];
  int _nextJob = 1;

  Map<String, dynamic> _publicJob() => <String, dynamic>{
        'id': 'job-1',
        'title': 'Junior Flutter Developer',
        'company_name': 'Example Nepal',
        'description': 'Build mobile features with a supportive product team.',
        'location': 'Kathmandu, Nepal',
        'employment_type': 'full-time',
        'work_mode': 'hybrid',
        'salary_min': 25000,
        'salary_max': 45000,
        'salary_currency': 'NPR',
        'skills': ['Flutter', 'Dart'],
        'status': 'published',
        'is_owner': false,
        'application_count': null,
      };

  Map<String, dynamic> _createdJob(Map<String, dynamic> posted) => <String, dynamic>{
        ...posted,
        'id': 'job-created',
        'salary_currency': 'NPR',
        'status': 'published',
        'is_owner': true,
        'application_count': 1,
      };

  Map<String, dynamic> _candidateApplication(String jobId) => <String, dynamic>{
        'id': 'application-1',
        'job_id': jobId,
        'applicant_name': 'Candidate Nepal',
        'cover_note': 'I have experience with Flutter and Dart.',
        'status': 'submitted',
        'created_at': '2026-10-10T00:00:00Z',
      };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    final key = '${request.method} $path';
    requests.add(key);
    var status = 200;
    dynamic payload;

    if (request.method == 'GET' && path == '/jobs') {
      if (request.url.queryParameters['mine'] == 'true') {
        payload = {
          'success': true,
          'jobs': postedJobs.map((posted) => _createdJob(posted)).toList(),
          'total': postedJobs.length,
          'limit': 50,
          'offset': 0,
        };
      } else {
        payload = {
          'success': true,
          'jobs': [_publicJob()],
          'total': 1,
          'limit': 50,
          'offset': 0,
        };
      }
    } else if (request.method == 'POST' && path == '/jobs') {
      final posted = Map<String, dynamic>.from(
        jsonDecode((request as http.Request).body) as Map,
      );
      postedJobs.add(posted);
      _nextJob++;
      payload = {'success': true, 'job': _createdJob(postedJobs.last)};
    } else if (request.method == 'POST' && path == '/jobs/job-1/applications') {
      final body = Map<String, dynamic>.from(
        jsonDecode((request as http.Request).body) as Map,
      );
      final application = {
        ..._candidateApplication('job-1'),
        'cover_note': body['cover_note'],
      };
      applications
        ..clear()
        ..add(application);
      payload = {'success': true, 'application': application};
    } else if (request.method == 'GET' && path == '/jobs/my-applications') {
      payload = {
        'success': true,
        'applications': applications.map((app) => {
          ...app,
          'job': _publicJob(),
        }).toList(),
      };
    } else if (request.method == 'GET' && path == '/jobs/job-created/applications') {
      payload = {
        'success': true,
        'applications': [_candidateApplication('job-created')],
      };
    } else if (request.method == 'PATCH' &&
        path == '/jobs/job-created/applications/application-1') {
      final body = Map<String, dynamic>.from(
        jsonDecode((request as http.Request).body) as Map,
      );
      applicationUpdates.add(body);
      payload = {
        'success': true,
        'application': {
          ..._candidateApplication('job-created'),
          'status': body['status'],
        },
      };
    } else {
      status = 404;
      payload = {'detail': 'Not found: $key'};
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
  testWidgets('Jobs screen searches, applies, posts a job and reviews applicants', (tester) async {
    final client = _JobsClient();
    final api = SageApi(
      client: client,
      baseUrl: 'http://test',
      authToken: 'test-token',
    );
    await tester.pumpWidget(MaterialApp(home: JobsScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('JOBS • NEPAL'), findsOneWidget);
    expect(find.text('Junior Flutter Developer'), findsOneWidget);

    await tester.tap(find.text('Junior Flutter Developer'));
    await tester.pumpAndSettle();
    expect(find.text('Apply'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'I have experience with Flutter and Dart.');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(client.requests, contains('POST /jobs/job-1/applications'));
    expect(find.text('Application submitted.'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'My applications'));
    await tester.pumpAndSettle();
    expect(client.requests, contains('GET /jobs/my-applications'));
    expect(find.text('Junior Flutter Developer'), findsOneWidget);
    expect(find.text('submitted'), findsOneWidget);

    await tester.tap(find.byTooltip('Post a job'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.decoration?.labelText == 'Job title (required)'),
      'Customer Support Associate',
    );
    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.decoration?.labelText == 'Company / employer (required)'),
      'Kathmandu Services',
    );
    await tester.enterText(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.decoration?.labelText == 'Description (at least 20 characters)'),
      'Help customers resolve product questions with care.',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Publish job'));
    await tester.pumpAndSettle();

    expect(client.requests, contains('POST /jobs'));
    expect(find.text('Customer Support Associate'), findsOneWidget);
    expect(find.text('Tap to review applicants'), findsOneWidget);

    await tester.tap(find.text('Customer Support Associate'));
    await tester.pumpAndSettle();
    expect(find.text('Applicants • Customer Support Associate'), findsOneWidget);
    expect(find.text('Candidate Nepal'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shortlisted').last);
    await tester.pumpAndSettle();

    expect(client.requests, contains('PATCH /jobs/job-created/applications/application-1'));
    expect(client.applicationUpdates.last['status'], 'shortlisted');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    api.dispose();
  });
}
