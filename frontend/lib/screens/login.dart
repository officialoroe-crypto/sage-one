import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/google_web_button.dart';
import '../core/identity_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.identity, required this.onSignedIn, super.key});

  final IdentityClient identity;
  final ValueChanged<Map<String, dynamic>> onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  bool _webReady = false;
  bool _developerMode = false;
    String? _error;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadIdentityConfig();
  }

  Future<void> _loadIdentityConfig() async {
    try {
      await widget.identity.loadConfig();
      if (!mounted) return;
      setState(() => _developerMode = widget.identity.developerMode);
      if (kIsWeb && !_developerMode) await _prepareWebGoogle();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
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

  Future<void> _handleWebAuthentication(GoogleSignInAuthenticationEvent event) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    setState(() { _loading = true; _error = null; });
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

  Future<void> _developerLogin() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.identity.devLogin();
      if (mounted) widget.onSignedIn(result);
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    if (kIsWeb) return;
    setState(() { _loading = true; _error = null; });
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
    return message.isEmpty ? 'Google sign-in failed. Please try again.' : message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
      super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = const Color(0xFF17D8FF);

    return Scaffold(
      backgroundColor: const Color(0xFF020306),
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBackdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 42, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      const _SageLoginMark(),
                      const SizedBox(height: 24),
                      const Text(
                        'S A G E   O N E',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          letterSpacing: 6.5,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'YOUR AI. YOUR EDGE.',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: primary.withOpacity(.82),
                          letterSpacing: 3.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 44),
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Enter SAGE ONE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to continue to your private workspace.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white54,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (_developerMode)
                              _LoginButton(
                                icon: Icons.bolt_rounded,
                                label: _loading ? 'Opening SAGE…' : 'Enter SAGE Owner Mode',
                                onPressed: _loading ? null : _developerLogin,
                                primary: true,
                              )
                            else if (kIsWeb)
                              SizedBox(
                                height: 54,
                                child: _webReady
                                    ? buildGoogleWebButton()
                                    : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            else
                              _LoginButton(
                                icon: Icons.g_mobiledata_rounded,
                                label: _loading ? 'Connecting to Google…' : 'Continue with Google',
                                onPressed: _loading ? null : _google,
                                primary: true,
                              ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withOpacity(.08))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'SECURE ACCESS',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white30,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white.withOpacity(.08))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _developerMode
                                  ? 'Local developer access is enabled for this build.'
                                  : 'Your Google identity is verified by SAGE on the server.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white38,
                                height: 1.45,
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.redAccent.withOpacity(.22)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SAGE ONE  •  PRIVATE BY DESIGN',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white24,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SageLoginMark extends StatelessWidget {
  const _SageLoginMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF173B61), Color(0xFF06101A), Color(0xFF020306)],
        ),
        border: Border.all(color: const Color(0xFF17D8FF).withOpacity(.42)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF17D8FF).withOpacity(.18), blurRadius: 38, spreadRadius: 5),
          BoxShadow(color: const Color(0xFF3E66FF).withOpacity(.14), blurRadius: 60, spreadRadius: 12),
        ],
      ),
      child: const Center(
        child: Text(
          'S',
          style: TextStyle(
            color: Color(0xFFBDF5FF),
            fontSize: 58,
            fontWeight: FontWeight.w200,
            letterSpacing: -4,
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF06101A).withOpacity(.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF17D8FF).withOpacity(.10)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 34, offset: const Offset(0, 18)),
        ],
      ),
      child: child,
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: onPressed == null
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 23),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: primary ? const Color(0xFF0C6179) : null,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -.45),
          radius: 1.15,
          colors: [
            const Color(0xFF0A2340).withOpacity(.75),
            const Color(0xFF030812).withOpacity(.95),
            const Color(0xFF020306),
          ],
          stops: const [0, .48, 1],
        ),
      ),
    );
  }
}
