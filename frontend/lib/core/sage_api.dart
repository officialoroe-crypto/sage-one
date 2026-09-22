import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SageApi {
  SageApi({http.Client? client, String? baseUrl, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage(),
        baseUrl = baseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:8010';
    return 'http://10.0.2.2:8010';
  }

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String baseUrl;

  Future<Map<String, dynamic>> routing() async {
    return _authorizedGet('/brain/routing');
  }

  Future<Map<String, dynamic>> submitBackground(String prompt) async {
    final response = await _authorizedPost('/execute/background', {'goal': prompt});
    final data = _decode(response);
    final task = data['task'];
    if (task is Map) {
      data['task_id'] = task['id'] ?? task['task_id'];
    }
    return data;
  }

  Future<Map<String, dynamic>> workerHealth() async {
    return _authorizedGet('/worker/health');
  }

  Future<Map<String, dynamic>> brainHealth() async {
    return _authorizedGet('/brain/health');
  }

  Future<List<dynamic>> tasks() async {
    final data = await _authorizedGet('/tasks');
    final items = data['tasks'] ?? data['items'] ?? data;
    return items is List ? items : <dynamic>[];
  }

  Future<Map<String, dynamic>> cancelTask(String taskId) async {
    return _authorizedPost('/tasks/$taskId/cancel', <String, dynamic>{});
  }

  Future<Map<String, dynamic>> task(String taskId) async {
    return _authorizedGet('/tasks/$taskId');
  }

  Future<List<dynamic>> notifications({bool unreadOnly = false, int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/notifications').replace(
      queryParameters: {
        'unread_only': unreadOnly.toString(),
        'limit': limit.toString(),
      },
    );
    final data = await _authorizedGetUri(uri);
    final items = data['notifications'] ?? data['items'] ?? data;
    return items is List ? items : <dynamic>[];
  }

  Future<Map<String, dynamic>> markNotificationRead(String notificationId) async {
    return _authorizedPost('/notifications/$notificationId/read', <String, dynamic>{});
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    return _authorizedPost('/notifications/read-all', <String, dynamic>{});
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
    final data = await _executeTool('research_get', {'research_id': researchId});
    final value = data['result'];
    return value is Map<String, dynamic> ? value : null;
  }

  Future<Map<String, dynamic>?> researchForTask(String taskId) async {
    final data = await _executeTool('research_by_task', {'task_id': taskId});
    final value = data['result'];
    return value is Map<String, dynamic> ? value : null;
  }

  Future<Map<String, dynamic>> worldStatus() async {
    return _authorizedGet('/world/status');
  }

  Future<List<dynamic>> worldKnowledge({int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/world/knowledge').replace(
      queryParameters: {'limit': limit.toString()},
    );
    final data = _decode(await _client.get(uri));
    final items = data['knowledge'] ?? data['items'] ?? data;
    return items is List ? items : <dynamic>[];
  }

  Future<List<dynamic>> worldDue() async {
    final data = await _authorizedGet('/world/due');
    final items = data['topics'] ?? data['items'] ?? data;
    return items is List ? items : <dynamic>[];
  }

  Future<Map<String, dynamic>> refreshWorld({List<String>? topics}) async {
    return _authorizedPost('/world/refresh', {'topics': topics ?? <String>[]});
  }

  Future<Map<String, dynamic>> ownerStatus() async => _authorizedGet('/economy/owner/status');

  Future<List<dynamic>> ownerAudit({int limit = 100}) async {
    final data = await _authorizedGet('/economy/owner/audit?limit=$limit');
    final items = data['events'] ?? const [];
    return items is List ? items : <dynamic>[];
  }

  Future<Map<String, dynamic>> ownerSetSpark(int amount, String reason) async =>
      _authorizedPost('/economy/owner/spark/set', {'amount': amount, 'reason': reason});
  Future<Map<String, dynamic>> ownerResetSpark(String reason) async =>
      _authorizedPost('/economy/owner/spark/reset', {'reason': reason});
  Future<Map<String, dynamic>> ownerSetEvolution(int achievement, String tier, String stage, String reason) async =>
      _authorizedPost('/economy/owner/evolution/set', {'lifetime_achievement': achievement, 'tier': tier, 'stage': stage, 'reason': reason});
  Future<Map<String, dynamic>> ownerSimulateEvolution(int achievement, {int durationMs = 3000}) async =>
      _authorizedPost('/economy/owner/evolution/simulate', {'target_achievement': achievement, 'duration_ms': durationMs});
  Future<Map<String, dynamic>> ownerResetEvolution(String reason) async =>
      _authorizedPost('/economy/owner/evolution/reset', {'reason': reason});

  Future<Map<String, dynamic>> economyMe() async {
    return _authorizedGet('/economy/me');
  }

  Future<List<dynamic>> premiumWorkCosts() async {
    final data = await _authorizedGet('/economy/costs');
    final items = data['costs'] ?? data['items'] ?? data;
    return items is List ? items : <dynamic>[];
  }

  Future<Map<String, dynamic>> _authorizedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await _identityToken();
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<String> _identityToken() async {
    final token = await _storage.read(key: 'sage.google.id_token') ??
        await _storage.read(key: 'sage.identity.token');
    if (token == null || token.isEmpty) {
      throw Exception('SAGE identity session is missing. Sign in again.');
    }
    return token;
  }

  Future<Map<String, dynamic>> _authorizedGet(String path) async {
    return _authorizedGetUri(Uri.parse('$baseUrl$path'));
  }

  Future<Map<String, dynamic>> _authorizedGetUri(Uri uri) async {
    final token = await _identityToken();
    final response = await _client.get(
      uri,
      headers: {'authorization': 'Bearer $token'},
    );
    return _decode(response);
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
    final token = await _identityToken();
    final response = await _client.post(
      uri,
      headers: {'authorization': 'Bearer $token'},
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    final body = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{'data': decoded};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['detail'] ?? body['error'] ?? 'SAGE API request failed');
    }
    return body;
  }

  void dispose() => _client.close();
}
