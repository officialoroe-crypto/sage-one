import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class IdentityClient {
  IdentityClient({
    http.Client? client,
    FlutterSecureStorage? storage,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage(),
        baseUrl = baseUrl ??
            const String.fromEnvironment(
              'SAGE_API_URL',
              defaultValue: 'http://localhost:8010',
            );

  static const _tokenKey = 'sage.google.id_token';
  static const _googleServerClientId = String.fromEnvironment(
    'SAGE_GOOGLE_SERVER_CLIENT_ID',
  );

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String baseUrl;
  bool _googleInitialized = false;

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      GoogleSignIn.instance.authenticationEvents;

  Future<String?> token() => _storage.read(key: _tokenKey);

  Future<void> initializeGoogle() async {
    if (_googleInitialized) return;

    String? clientId;
    String? serverClientId =
        _googleServerClientId.isEmpty ? null : _googleServerClientId;

    if (kIsWeb) {
      final response = await _client.get(Uri.parse('$baseUrl/identity/config'));
      final data = _decode(response);
      final configuredClientId = data['google_client_id'];
      if (configuredClientId is! String || configuredClientId.isEmpty) {
        throw Exception('Google web client ID is not configured on SAGE.');
      }
      clientId = configuredClientId;
      serverClientId ??= configuredClientId;
    }

    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    _googleInitialized = true;
  }

  Future<void> signOut() async {
    try {
      await initializeGoogle();
      await GoogleSignIn.instance.signOut();
    } finally {
      await _storage.delete(key: _tokenKey);
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    await initializeGoogle();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception('Use the Google sign-in button on web.');
    }

    final account = await GoogleSignIn.instance.authenticate();
    return signInWithGoogleAccount(account);
  }

  Future<Map<String, dynamic>> signInWithGoogleAccount(
    GoogleSignInAccount account,
  ) async {
    final idToken = account.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google did not return an ID token.');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/identity/google'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );

    final data = _decode(response);
    await _storage.write(key: _tokenKey, value: idToken);
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    return _authorized('GET', '/identity/me');
  }

  Future<Map<String, dynamic>> onboardingOptions() async {
    return _authorized('GET', '/identity/onboarding/options');
  }

  Future<Map<String, dynamic>> sendPhoneOtp(String phone) async {
    return _authorized(
      'POST',
      '/identity/phone/send',
      body: {'phone': phone},
    );
  }

  Future<Map<String, dynamic>> verifyPhoneOtp(
    String challengeId,
    String code,
  ) async {
    return _authorized(
      'POST',
      '/identity/phone/verify',
      body: {
        'challenge_id': challengeId,
        'code': code,
      },
    );
  }

  Future<Map<String, dynamic>> completeOnboarding({
    required String name,
    required String phone,
    required String address,
    required int age,
    required String helpIntent,
    required List<String> capabilities,
    required bool memoryConsent,
  }) async {
    return _authorized(
      'POST',
      '/identity/onboarding',
      body: {
        'name': name,
        'phone': phone,
        'address': address,
        'age': age,
        'basic_info': <String, dynamic>{},
        'help_intent': helpIntent,
        'capabilities': capabilities,
        'memory_consent': memoryConsent,
      },
    );
  }

  Future<Map<String, dynamic>> _authorized(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final idToken = await token();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('SAGE identity session is missing. Sign in again.');
    }

    final headers = <String, String>{
      'authorization': 'Bearer $idToken',
      'content-type': 'application/json',
    };

    final uri = Uri.parse('$baseUrl$path');
    final http.Response response;
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        );
        break;
      default:
        throw UnsupportedError('Unsupported identity method: $method');
    }

    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{'data': decoded};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['detail'] ?? 'SAGE identity request failed');
    }

    return data;
  }

  void dispose() => _client.close();
}
