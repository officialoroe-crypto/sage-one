import 'package:flutter/material.dart';
import '../core/sage_api.dart';
import '../theme/sage_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.api, super.key});
  final SageApi api;
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _Message {
  const _Message(this.text, this.user);
  final String text;
  final bool user;
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Message>[
    const _Message('I’m here. Tell me what you need, and I’ll work with you.', false),
  ];
  String? _sessionId;
  bool _sending = false;

  Future<void> _send() async {
    final message = _input.text.trim();
    if (message.isEmpty || _sending) return;
    setState(() {
      _messages.add(_Message(message, true));
      _input.clear();
      _sending = true;
    });
    try {
      final data = await widget.api.chat(message: message, sessionId: _sessionId);
      final session = data['session_id'];
      if (session is String && session.isNotEmpty) _sessionId = session;
      final response = widget.api.chatResponseText(data['response']);
      if (mounted) {
        setState(() => _messages.add(_Message(
          response.isEmpty ? 'SAGE returned an empty response.' : response,
          false,
        )));
      }
    } catch (error) {
      if (mounted) setState(() => _messages.add(_Message('SAGE Core error: $error', false)));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SageTheme.voidBlack,
    appBar: AppBar(title: const Text('SAGE CHAT'), backgroundColor: Colors.transparent),
    body: Column(children: [
      Expanded(child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (_, i) {
          final m = _messages[i];
          return Align(
            alignment: m.user ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: m.user ? SageTheme.cyan.withValues(alpha: .13) : SageTheme.surface,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Text(m.text, style: const TextStyle(color: SageTheme.textPrimary, height: 1.45)),
            ),
          );
        },
      )),
      SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: TextField(
            controller: _input,
            minLines: 1,
            maxLines: 5,
            onSubmitted: (_) => _send(),
            decoration: const InputDecoration(hintText: 'Message SAGE…'),
          )),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send message',
            onPressed: _sending ? null : _send,
            icon: Icon(_sending ? Icons.hourglass_top : Icons.send),
          ),
        ]),
      )),
    ]),
  );
}
