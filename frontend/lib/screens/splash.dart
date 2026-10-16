import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/sage_theme.dart';
import '../widgets/sage_brand_mark.dart';

/// Branded entry transition. Authentication is shown only after this finishes.
class SageSplashScreen extends StatefulWidget {
  const SageSplashScreen({
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 1600),
  });

  final Widget child;
  final Duration duration;

  @override
  State<SageSplashScreen> createState() => _SageSplashScreenState();
}

class _SageSplashScreenState extends State<SageSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  Timer? _timer;
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _timer = Timer(widget.duration, () {
      if (mounted) setState(() => _complete = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_complete) return widget.child;

    return Scaffold(
      backgroundColor: SageTheme.voidBlack,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.22),
            radius: 1.15,
            colors: [
              Color(0xFF102A56),
              Color(0xFF061326),
              Color(0xFF020306),
            ],
            stops: [0, .52, 1],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: .92 + (_controller.value * .08),
                    child: const SageBrandMark(size: 158),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'SAGE ONE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 7,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'YOUR PERSONAL AI MENTOR & EXECUTION PARTNER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SageTheme.cyan,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 92,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.white12,
                      valueColor:
                          const AlwaysStoppedAnimation(SageTheme.cyan),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
