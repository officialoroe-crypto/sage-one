import 'package:flutter/material.dart';
import '../theme/sage_theme.dart';

class VoiceResponseScreen extends StatefulWidget {
  const VoiceResponseScreen({super.key, this.response = 'Your SAGE response is ready.'});
  final String response;
  @override State<VoiceResponseScreen> createState() => _VoiceResponseScreenState();
}

class _VoiceResponseScreenState extends State<VoiceResponseScreen> {
  bool _playing = false;
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: SageTheme.voidBlack,
    appBar: AppBar(title: const Text('SAGE RESPONSE'), backgroundColor: Colors.transparent),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          width: 132, height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SageTheme.surface,
            border: Border.all(color: SageTheme.cyan.withValues(alpha: .38)),
            boxShadow: [BoxShadow(color: SageTheme.cyan.withValues(alpha: _playing ? .34 : .18), blurRadius: _playing ? 48 : 30, spreadRadius: _playing ? 10 : 4)],
          ),
          child: const Center(child: Text('S', style: TextStyle(fontSize: 58, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(height: 34),
        const Text('SAGE HAS RESPONDED', style: TextStyle(fontSize: 11, letterSpacing: 2.2, color: SageTheme.cyan, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Text(widget.response, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, height: 1.45, fontWeight: FontWeight.w600)),
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: () => setState(() => _playing = !_playing), icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 54, color: SageTheme.cyan)),
          const SizedBox(width: 18),
          IconButton(onPressed: () {}, icon: const Icon(Icons.replay, size: 28)),
        ]),
        const Spacer(),
        const Text('Voice playback is user-controlled.', style: TextStyle(color: SageTheme.textSecondary, fontSize: 11)),
      ]),
    ),
  );
}
