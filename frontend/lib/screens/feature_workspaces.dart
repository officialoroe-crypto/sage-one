import 'dart:async';

import 'package:flutter/material.dart';
import '../core/sage_api.dart';
import '../theme/sage_theme.dart';

class FeatureWorkspace extends StatefulWidget {
  const FeatureWorkspace({required this.title, required this.subtitle, required this.icon, required this.actions, super.key});
  final String title, subtitle; final IconData icon; final List<String> actions;
  @override State<FeatureWorkspace> createState() => _FeatureWorkspaceState();
}
class _FeatureWorkspaceState extends State<FeatureWorkspace> {
  Future<void> _explainAction(String action) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: Text(
          '${widget.title} is present in the SAGE ONE interface, but this action is not connected to a live workflow yet. '
          'It will not report success or change account data until its backend integration is implemented.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SageTheme.voidBlack,
    appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.transparent),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0C2344), Color(0xFF07101E)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SageTheme.cyan.withValues(alpha: .18)),
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SageTheme.cyan.withValues(alpha: .1),
            ),
            child: Icon(widget.icon, color: SageTheme.cyan),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: SageTheme.textPrimary,
              )),
              const SizedBox(height: 5),
              Text(widget.subtitle, style: const TextStyle(
                color: SageTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              )),
            ],
          )),
        ]),
      ),
      const SizedBox(height: 20),
      const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline, color: SageTheme.textSecondary),
          title: Text('Integration status'),
          subtitle: Text(
            'Interface available • Live actions not connected yet',
          ),
        ),
      ),
      const SizedBox(height: 12),
      ...widget.actions.map((action) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FilledButton.tonalIcon(
          onPressed: () => _explainAction(action),
          icon: const Icon(Icons.info_outline),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(action),
          ),
        ),
      )),
    ]),
  );
}

enum _ChatRecoveryAction { session, command, history, taskStatus }

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.api, super.key});
  final SageApi api;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const int _maxPollFailures = 5;

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _messages = <Map<String, String>>[];
  String? _sessionId;
  String? _taskId;
  Timer? _poller;
  int _sessionGeneration = 0;
  int _pollFailures = 0;
  bool _pollInFlight = false;
  bool _sending = false;
  String _status = 'Ready';
  String? _chatError;
  _ChatRecoveryAction? _recoveryAction;

  @override
  void initState() {
    super.initState();
    _newSession();
  }

  Future<void> _newSession() async {
    // Invalidate in-flight work before clearing the previous conversation.
    final generation = ++_sessionGeneration;
    _poller?.cancel();
    _pollFailures = 0;
    if (mounted) {
      setState(() {
        _sessionId = null;
        _taskId = null;
        _sending = true;
        _status = 'Starting new session…';
        _chatError = null;
        _recoveryAction = null;
        _messages.clear();
      });
    }
    try {
      final session = await widget.api.createSession();
      final value = session['session'];
      final id = value is Map ? value['id']?.toString() : null;
      if (id == null || id.isEmpty) {
        throw Exception('SAGE did not return a session id.');
      }
      if (!mounted || generation != _sessionGeneration) return;
      setState(() {
        _sessionId = id;
        _sending = false;
        _status = 'Ready';
        _chatError = null;
        _recoveryAction = null;
      });
    } catch (error) {
      if (!mounted || generation != _sessionGeneration) return;
      setState(() {
        _sending = false;
        _status = 'Could not start chat';
        _chatError = 'Could not start chat. Check the API connection, then retry. Details: $error';
        _recoveryAction = _ChatRecoveryAction.session;
      });
    }
  }

  Future<void> _loadHistory({
    required int generation,
    required String sessionId,
  }) async {
    if (generation != _sessionGeneration || sessionId != _sessionId) return;
    try {
      final items = await widget.api.sessionMessages(sessionId);
      if (!mounted ||
          generation != _sessionGeneration ||
          sessionId != _sessionId) {
        return;
      }
      setState(() {
        _messages
          ..clear()
          ..addAll(items.whereType<Map>().map((item) => {
                'role': (item['role'] ?? '').toString(),
                'content': (item['content'] ?? '').toString(),
              }));
        if (_recoveryAction == _ChatRecoveryAction.history) {
          _chatError = null;
          _recoveryAction = null;
          _status = 'Ready';
        }
      });
    } catch (error) {
      if (!mounted ||
          generation != _sessionGeneration ||
          sessionId != _sessionId) {
        return;
      }
      setState(() {
        _status = 'History unavailable';
        _chatError = 'Chat history could not load. Your session is still active. Retry to load it again. Details: $error';
        _recoveryAction = _ChatRecoveryAction.history;
      });
    }
  }

  Future<void> _refreshHistory() async {
    final sessionId = _sessionId;
    if (sessionId == null || _sending) return;
    await _loadHistory(
      generation: _sessionGeneration,
      sessionId: sessionId,
    );
  }

  Future<void> _openSession(String sessionId) async {
    final generation = ++_sessionGeneration;
    _poller?.cancel();
    _pollFailures = 0;
    setState(() {
      _sessionId = sessionId;
      _taskId = null;
      _messages.clear();
      _sending = true;
      _status = 'Loading saved conversation…';
      _chatError = null;
      _recoveryAction = null;
    });
    await _loadHistory(generation: generation, sessionId: sessionId);
    if (!mounted || generation != _sessionGeneration) return;
    setState(() {
      _sending = false;
      if (_chatError == null) _status = 'Saved conversation loaded';
    });
  }

  Future<void> _openHistory() async {
    try {
      final activeRaw = await widget.api.chatSessions();
      final archivedRaw = await widget.api.chatSessions(archived: true);
      if (!mounted) return;
      final active = activeRaw.whereType<Map>().map((item) =>
          Map<String, dynamic>.from(item)).toList();
      final archived = archivedRaw.whereType<Map>().map((item) =>
          Map<String, dynamic>.from(item)).toList();
      var showArchived = false;
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final items = showArchived ? archived : active;
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * .72,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Chat archive',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          ),
                          TextButton(
                            onPressed: () => setSheetState(() => showArchived = !showArchived),
                            child: Text(showArchived ? 'Active chats' : 'Archived'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? Center(child: Text(showArchived
                              ? 'No archived conversations yet.'
                              : 'No saved conversations yet.'))
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final id = item['id']?.toString() ?? '';
                                final preview = item['preview']?.toString().trim() ?? '';
                                final count = item['message_count'] ?? 0;
                                return ListTile(
                                  leading: const Icon(Icons.chat_bubble_outline),
                                  title: Text(preview.isEmpty ? 'Conversation' : preview,
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                  subtitle: Text('$count messages'),
                                  onTap: id.isEmpty ? null : () => Navigator.of(sheetContext).pop(id),
                                  trailing: IconButton(
                                    tooltip: showArchived ? 'Restore conversation' : 'Archive conversation',
                                    icon: Icon(showArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
                                    onPressed: id.isEmpty ? null : () async {
                                      try {
                                        if (showArchived) {
                                          await widget.api.restoreChatSession(id);
                                          archived.removeWhere((entry) => entry['id']?.toString() == id);
                                          active.insert(0, item);
                                        } else {
                                          await widget.api.archiveChatSession(id);
                                          active.removeWhere((entry) => entry['id']?.toString() == id);
                                          archived.insert(0, item);
                                        }
                                        setSheetState(() {});
                                      } catch (error) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Could not update archive: $error')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      if (selected != null && selected.isNotEmpty && mounted) {
        await _openSession(selected);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat archive could not load: $error')),
      );
    }
  }

  void _retryRecovery() {
    switch (_recoveryAction) {
      case _ChatRecoveryAction.session:
        _newSession();
        break;
      case _ChatRecoveryAction.command:
        _send();
        break;
      case _ChatRecoveryAction.history:
        _refreshHistory();
        break;
      case _ChatRecoveryAction.taskStatus:
        final sessionId = _sessionId;
        if (sessionId != null && _taskId != null) {
          _startPolling(
            generation: _sessionGeneration,
            sessionId: sessionId,
          );
        }
        break;
      case null:
        return;
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (_sessionId == null) await _newSession();
    final sessionId = _sessionId;
    if (sessionId == null || _sending) return;
    final generation = _sessionGeneration;

    setState(() {
      _sending = true;
      _status = 'Sending to SAGE…';
      _chatError = null;
      _recoveryAction = null;
      _messages.add({'role': 'user', 'content': text});
      _input.clear();
    });

    try {
      final response = await widget.api.chat(text, sessionId: sessionId);
      if (!mounted || generation != _sessionGeneration) return;
      if (response['success'] != true) {
        throw Exception(response['error'] ?? 'SAGE could not complete the reply.');
      }

      final raw = response['response'];
      String reply = '';
      if (raw is Map) {
        reply = (raw['response'] ?? raw['text'] ?? raw['content'] ?? '').toString();
      } else if (raw is String) {
        reply = raw;
      }
      if (reply.trim().isEmpty) {
        throw Exception('SAGE returned an empty reply. Please retry.');
      }

      setState(() {
        _sessionId = response['session_id']?.toString() ?? sessionId;
        _messages.add({'role': 'assistant', 'content': reply.trim()});
        _sending = false;
        _status = 'Response received';
        _chatError = null;
        _recoveryAction = null;
      });
      await _loadHistory(generation: generation, sessionId: _sessionId!);
    } catch (error) {
      if (!mounted || generation != _sessionGeneration) return;
      setState(() {
        if (_messages.isNotEmpty &&
            _messages.last['role'] == 'user' &&
            _messages.last['content'] == text) {
          _messages.removeLast();
        }
        _input.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        _sending = false;
        _status = 'Chat failed';
        _chatError = 'SAGE could not reply. Your message has been restored so you can retry. Details: $error';
        _recoveryAction = _ChatRecoveryAction.command;
      });
    }
  }

  void _startPolling({
    required int generation,
    required String sessionId,
  }) {
    _poller?.cancel();
    _pollFailures = 0;
    if (mounted) {
      setState(() {
        _sending = true;
        _status = 'Waiting for task…';
        _chatError = null;
        _recoveryAction = null;
      });
    }
    _poller = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollTask(generation: generation, sessionId: sessionId),
    );
    _pollTask(generation: generation, sessionId: sessionId);
  }

  Future<void> _pollTask({
    required int generation,
    required String sessionId,
  }) async {
    if (generation != _sessionGeneration ||
        sessionId != _sessionId ||
        _pollInFlight) {
      return;
    }
    final id = _taskId;
    if (id == null) return;
    _pollInFlight = true;
    try {
      final task = await widget.api.task(id);
      if (!mounted ||
          generation != _sessionGeneration ||
          sessionId != _sessionId) {
        return;
      }
      final status = (task['status'] ?? 'unknown').toString().toLowerCase();
      final result = task['result']?.toString();
      final error = task['error']?.toString();
      _pollFailures = 0;
      setState(() {
        _chatError = null;
        _recoveryAction = null;
        _status = status.toUpperCase();
        if (status == 'completed' && result != null && result.isNotEmpty) {
          _messages.add({'role': 'assistant', 'content': result});
        } else if (status == 'failed' && error != null && error.isNotEmpty) {
          _messages.add({'role': 'system', 'content': error});
        }
        _sending = !{'completed', 'failed', 'cancelled', 'canceled'}.contains(status);
      });
      if (!_sending) {
        _poller?.cancel();
        await _loadHistory(generation: generation, sessionId: sessionId);
      }
    } catch (error) {
      if (!mounted ||
          generation != _sessionGeneration ||
          sessionId != _sessionId) {
        return;
      }
      _pollFailures++;
      if (_pollFailures >= _maxPollFailures) {
        _poller?.cancel();
        setState(() {
          _status = 'Status check paused';
          _chatError = 'SAGE has not confirmed the task status after $_maxPollFailures attempts. The task may still be running; retry the status check before sending another command. Details: $error';
          _recoveryAction = _ChatRecoveryAction.taskStatus;
        });
      } else {
        setState(() {
          _status = 'Connection issue • retry $_pollFailures/$_maxPollFailures';
        });
      }
    } finally {
      _pollInFlight = false;
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SageTheme.voidBlack,
      appBar: AppBar(
        title: const Text('SAGE Chat'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Open chat archive',
            onPressed: _sending ? null : _openHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Refresh chat history',
            onPressed: _sessionId == null || _sending ? null : _refreshHistory,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'New chat session',
            onPressed: _newSession,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_chatError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: SageTheme.failure),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _chatError!,
                          style: const TextStyle(color: SageTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _recoveryAction == null ? null : _retryRecovery,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Talk to SAGE. Every command enters the durable execution pipeline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SageTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final item = _messages[index];
                      final role = item['role'] ?? 'system';
                      final isUser = role == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 620),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser ? SageTheme.blue.withValues(alpha: .24) : SageTheme.cyan.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: SageTheme.cyan.withValues(alpha: .12)),
                          ),
                          child: SelectableText(
                            item['content'] ?? '',
                            style: const TextStyle(color: SageTheme.textPrimary, height: 1.45),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !_sending,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask SAGE to do something…',
                      suffixText: _status,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppsScreen extends StatelessWidget { const AppsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Apps',subtitle:'Connected tools and future integrations in one control surface.',icon:Icons.apps,actions:['Browse connected apps','Connect an app','Manage permissions']);}
class EarningsScreen extends StatelessWidget { const EarningsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Earnings',subtitle:'Track completed work, payouts and creator income.',icon:Icons.trending_up,actions:['View earnings','View pending payouts','Open earnings history']);}
class CommunityScreen extends StatelessWidget { const CommunityScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Community',subtitle:'Private-first collaboration and future SAGE community spaces.',icon:Icons.groups_outlined,actions:['Open community','Create a post','View activity']);}
class FileManagerScreen extends StatelessWidget { const FileManagerScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'File Manager',subtitle:'Organize SAGE artifacts, project files and exports.',icon:Icons.folder_copy_outlined,actions:['Browse files','Recent artifacts','Export workspace']);}
class AiStudioScreen extends StatelessWidget { const AiStudioScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'AI Studio',subtitle:'Build reusable prompts, agents and execution recipes.',icon:Icons.auto_awesome,actions:['Create a workflow','Prompt library','Agent templates']);}
class SparkWalletScreen extends StatelessWidget { const SparkWalletScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Spark Wallet',subtitle:'SAGE Spark balance and internal work-credit controls.',icon:Icons.account_balance_wallet_outlined,actions:['View Spark balance','Open Spark history','Reserve Spark']);}
class PaymentScreen extends StatelessWidget { const PaymentScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Payments',subtitle:'Payment setup and provider readiness.',icon:Icons.payments_outlined,actions:['Payment methods','Provider status','Payment preferences']);}
class TransactionsScreen extends StatelessWidget { const TransactionsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Transactions',subtitle:'Unified record of work, Spark and payment movements.',icon:Icons.receipt_long_outlined,actions:['View transactions','Filter records','Export records']);}
class ProfileScreen extends StatelessWidget { const ProfileScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Profile',subtitle:'Identity, capabilities and personal SAGE preferences.',icon:Icons.person_outline,actions:['Edit profile','Capabilities','Privacy controls']);}
class SettingsScreen extends StatelessWidget { const SettingsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Settings',subtitle:'Themes, behavior, language and security controls.',icon:Icons.settings_outlined,actions:['Appearance','Language','Security']);}
class NotificationsScreen extends StatelessWidget { const NotificationsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Notifications',subtitle:'Activity, alerts and SAGE execution updates.',icon:Icons.notifications_none,actions:['View notifications','Mark all read','Notification preferences']);}

class KycScreen extends StatefulWidget {
  const KycScreen({required this.api, super.key});
  final SageApi api;

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _loading = true;
  bool _working = false;
  bool _phoneVerified = false;
  String? _challengeId;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await widget.api.profileMe();
      final raw = response['profile'];
      final profile = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _phone.text = profile['phone']?.toString() ?? _phone.text;
        _phoneVerified = profile['phone_verified'] == true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _sendCode() async {
    final phone = _phone.text.trim();
    if (phone.length < 5) {
      setState(() => _error = 'Enter a valid phone number, including country code.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
      _message = null;
    });
    try {
      final response = await widget.api.sendIdentityPhoneOtp(phone);
      final delivery = response['delivery']?.toString();
      if (delivery != 'sms_provider') {
        if (!mounted) return;
        setState(() {
          _challengeId = null;
          _message = null;
          _error = 'SMS delivery is not configured on the SAGE backend. No code was sent and your phone is not verified.';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _challengeId = response['challenge_id']?.toString();
        _message = _challengeId == null
            ? 'SAGE did not return a verification challenge.'
            : 'Verification code sent. Enter the six-digit code.';
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _verifyCode() async {
    final challenge = _challengeId;
    final code = _code.text.trim();
    if (challenge == null) {
      setState(() => _error = 'Send a verification code first.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the six-digit verification code.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
      _message = null;
    });
    try {
      final response = await widget.api.verifyIdentityPhoneOtp(challenge, code);
      if (response['phone_verified'] != true) {
        throw Exception('The backend did not confirm phone verification.');
      }
      if (!mounted) return;
      setState(() {
        _phoneVerified = true;
        _challengeId = null;
        _code.clear();
        _message = 'Phone number verified by SAGE.';
      });
      await _loadStatus();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SageTheme.voidBlack,
    appBar: AppBar(title: const Text('Identity Verification'), backgroundColor: Colors.transparent),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0C2344), Color(0xFF07101E)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SageTheme.cyan.withValues(alpha: .18)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, color: SageTheme.cyan, size: 34),
              SizedBox(height: 12),
              Text('REAL VERIFICATION STATUS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('SAGE shows only verification confirmed by the backend. Phone verification is not the same as formal KYC.', style: TextStyle(color: SageTheme.textSecondary, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(_phoneVerified ? Icons.verified : Icons.phone_android, color: _phoneVerified ? SageTheme.success : SageTheme.cyan),
            title: const Text('Phone verification'),
            subtitle: Text(_loading ? 'Checking backend status…' : _phoneVerified ? 'Verified by SAGE backend' : 'Not verified'),
            trailing: IconButton(onPressed: _loading || _working ? null : _loadStatus, icon: const Icon(Icons.refresh), tooltip: 'Refresh status'),
          ),
        ),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            leading: Icon(Icons.assignment_ind_outlined, color: SageTheme.textSecondary),
            title: Text('Formal KYC'),
            subtitle: Text('No KYC provider is connected yet. Government ID or biometric verification is not available and must not be treated as complete.'),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          enabled: !_phoneVerified && !_working,
          decoration: const InputDecoration(labelText: 'Phone number', hintText: '+977…', prefixIcon: Icon(Icons.phone_outlined)),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _working || _loading || _phoneVerified ? null : _sendCode,
          icon: const Icon(Icons.sms_outlined),
          label: Text(_working ? 'Working…' : 'Send verification code'),
        ),
        if (_challengeId != null) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: '6-digit code', prefixIcon: Icon(Icons.password_outlined)),
          ),
          FilledButton.icon(
            onPressed: _working ? null : _verifyCode,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Verify phone'),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, style: const TextStyle(color: SageTheme.success)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          SelectableText(_error!, style: const TextStyle(color: SageTheme.failure)),
        ],
        if (_loading) const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator())),
      ],
    ),
  );
}
class FirstRunScreen extends StatelessWidget { const FirstRunScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'First Run',subtitle:'Finish setup and choose how SAGE should work with you.',icon:Icons.flag_outlined,actions:['Complete setup','Choose capabilities','Finish workspace setup']);}
