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
      body: jsonEncode({'prompt': prompt}),
    );
    return _decode(response);
  }

  Future<List<dynamic>> tasks() async {
    final response = await _client.get(Uri.parse('$baseUrl/tasks'));
    final data = _decode(response);
    final items = data['tasks'] ?? data['items'] ?? data;
    return items is List ? items : <dynamic>[];
  }

  Future<Map<String, dynamic>> task(String taskId) async {
    final response = await _client.get(Uri.parse('$baseUrl/tasks/$taskId'));
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
