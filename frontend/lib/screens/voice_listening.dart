import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/sage_theme.dart';

class VoiceListeningScreen extends StatefulWidget {
  const VoiceListeningScreen({super.key});
  @override State<VoiceListeningScreen> createState() => _VoiceListeningScreenState();
}

class _VoiceListeningScreenState extends State<VoiceListeningScreen> {
  final _speech = stt.SpeechToText();
  String _text = '';
  String _status = 'Microphone is ready when you are.';
  bool _available = false;
  bool _listening = false;

  Future<void> _start() async {
    try {
      _available = await _speech.initialize(
        onStatus: (status) {
          if (mounted) setState(() => _status = status);
        },
        onError: (error) {
          if (mounted) setState(() => _status = error.errorMsg);
        },
      );
      if (!_available) {
        setState(() => _status = 'Speech recognition is unavailable or permission was denied.');
        return;
      }
      setState(() {
        _listening = true;
        _status = 'Listening…';
      });
      await _speech.listen(
        onResult: (result) {
          if (mounted) setState(() => _text = result.recognizedWords);
        },
      );
    } catch (error) {
      if (mounted) setState(() => _status = 'Voice input failed: $error');
    }
  }

  Future<void> _stop() async {
    await _speech.stop();
    if (mounted) {
      setState(() {
        _listening = false;
        _status = _text.isEmpty ? 'Listening stopped.' : 'Voice captured.';
      });
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SageTheme.voidBlack,
    appBar: AppBar(title: const Text('VOICE LISTENING'), backgroundColor: Colors.transparent),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(_listening ? Icons.mic : Icons.mic_none, size: 78, color: SageTheme.cyan),
        const SizedBox(height: 20),
        Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: SageTheme.textSecondary)),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SageTheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _text.isEmpty ? 'Your words will appear here.' : _text,
            style: const TextStyle(color: SageTheme.textPrimary, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _listening ? _stop : _start,
          icon: Icon(_listening ? Icons.stop : Icons.mic),
          label: Text(_listening ? 'Stop listening' : 'Start listening'),
        ),
      ]),
    )),
  );
}
