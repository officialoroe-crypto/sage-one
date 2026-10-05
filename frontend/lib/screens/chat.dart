import 'dart:async';

import 'package:flutter/material.dart';

import '../core/sage_api.dart';
import '../theme/sage_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.api, super.key});
  final SageApi api;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});
  final String text;
  final bool fromUser;
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_ChatMessage>[];
  String? _sessionId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(const _ChatMessage(
      text: 'I’m here. Tell me what you need, and I’ll work with you.',
      fromUser: false,
    ));
  }

  Future<void> _send() async {
    final message = _input.text.trim();
    if (message.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text: message, fromUser: true));
      _input.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final data = await widget.api.chat(message: message, sessionId: _sessionId);
      final nextSession = data['session_id'];
      if (nextSession is String && nextSession.isNotEmpty) {
        _sessionId = nextSession;
      }
      final response = data['response'];
      final text = widget.api.chatResponseText(response);
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(
        text: text.isEmpty ? 'SAGE returned an empty response.' : text,
        fromUser: false,
      )));
    } catch (error) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMessage(
        text: 'I could not reach SAGE Core: $error',
        fromUser: false,
      )));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SageTheme.voidBlack,
      appBar: AppBar(
        title: const Text('SAGE CHAT'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_sessionId != null)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.cloud_done, color: SageTheme.success, size: 18),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: message.fromUser
                          ? SageTheme.cyan.withValues(alpha: .13)
                          : SageTheme.surface,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: message.fromUser
                            ? SageTheme.cyan.withValues(alpha: .28)
                            : SageTheme.violet.withValues(alpha: .16),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        color: SageTheme.textPrimary,
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Message SAGE…',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: _sending ? null : _send,
                    icon: Icon(_sending ? Icons.hourglass_top : Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
