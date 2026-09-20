import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/google_web_button.dart';
import '../core/identity_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.identity,
    required this.onSignedIn,
    super.key,
  });

  final IdentityClient identity;
  final ValueChanged<Map<String, dynamic>> onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  bool _webReady = false;
  String? _error;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _prepareWebGoogle();
    }
  }

  Future<void> _prepareWebGoogle() async {
    try {
      await widget.identity.initializeGoogle();
      _authSubscription = widget.identity.authenticationEvents.listen(
        _handleWebAuthentication,
        onError: _handleWebAuthenticationError,
      );
      if (mounted) setState(() => _webReady = true);
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    }
  }

  Future<void> _handleWebAuthentication(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.identity.signInWithGoogleAccount(event.user);
      if (mounted) widget.onSignedIn(result);
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleWebAuthenticationError(Object error) {
    if (mounted) setState(() => _error = _friendlyError(error));
  }

  Future<void> _google() async {
    if (kIsWeb) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.identity.signInWithGoogle();
      if (mounted) widget.onSignedIn(result);
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) return 'Google sign-in failed. Please try again.';
    return message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyanAccent.withOpacity(.7)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(.2),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w300,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'S A G E   O N E',
                    style: TextStyle(
                      fontSize: 22,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'More than an AI.\nIt’s your edge.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 42),
                  if (kIsWeb)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: _webReady
                          ? buildGoogleWebButton()
                          : const Center(child: CircularProgressIndicator()),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _google,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.g_mobiledata, size: 28),
                        label: Text(
                          _loading ? 'Connecting to Google…' : 'Continue with Google',
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your Google ID token is verified by SAGE on the server.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.redAccent.withOpacity(.25)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
