import 'dart:convert';

import 'package:http/http.dart' as http;

class SageApi {
  SageApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment(
          'SAGE_API_URL',
          defaultValue: 'http://10.0.2.2:8010',
        );

  final http.Client _client;
  final String baseUrl;

  Future<Map<String, dynamic>> routing() async {
    final response = await _client.get(Uri.parse('$baseUrl/brain/routing'));
    return _decode(response);
  }

  Future<Map<String, dynamic>> submitBackground(String prompt) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/execute/background'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'goal': prompt}),
    );
    return _decode(response);
  }

  Future<List<dynamic>> tasks() async {
    final response = await _client.get(Uri.parse('$baseUrl/tasks'));
    final data = _decode(response);
    final items = data['tasks'] ?? data['items'] ?? data;
    return items is List ? items : <dynamic>[];
  }

  Future<Map<String, dynamic>> cancelTask(String taskId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/tasks/$taskId/cancel'),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> task(String taskId) async {
    final response = await _client.get(Uri.parse('$baseUrl/tasks/$taskId'));
    return _decode(response);
  }


  Future<List<dynamic>> notifications({bool unreadOnly = false, int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/notifications').replace(
      queryParameters: {
        'unread_only': unreadOnly.toString(),
        'limit': limit.toString(),
      },
    );
    final data = _decode(await _client.get(uri));
    final items = data['notifications'] ?? data['items'] ?? data;
    return items is List ? items : <dynamic>[];
  }

  Future<Map<String, dynamic>> markNotificationRead(String notificationId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/notifications/read-all'),
    );
    return _decode(response);
  }

  Future<List<dynamic>> researchHistory({String? sessionId, int limit = 20}) async {
    final arguments = <String, dynamic>{'limit': limit};
    if (sessionId != null && sessionId.isNotEmpty) {
      arguments['session_id'] = sessionId;
    }
    final data = await _executeTool('research_list', arguments);
    final items = data['result'] ?? data['items'] ?? data;
    return items is List ? items : <dynamic>[];
  }

  Future<Map<String, dynamic>?> research(String researchId) async {
    final data = await _executeTool('research_get', {
      'research_id': researchId,
    });
    final value = data['result'];
    return value is Map<String, dynamic> ? value : null;
  }

  Future<Map<String, dynamic>?> researchForTask(String taskId) async {
    final data = await _executeTool('research_by_task', {'task_id': taskId});
    final value = data['result'];
    return value is Map<String, dynamic> ? value : null;
  }

  Future<Map<String, dynamic>> _executeTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    final uri = Uri.parse('$baseUrl/tools/execute').replace(
      queryParameters: {
        'tool_name': toolName,
        'arguments': jsonEncode(arguments),
      },
    );
    final response = await _client.post(uri);
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['detail'] ?? 'SAGE API request failed');
    }
    return body;
  }

  void dispose() => _client.close();
}
