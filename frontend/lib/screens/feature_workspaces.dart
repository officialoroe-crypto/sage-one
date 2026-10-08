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
  String? _message;
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: SageTheme.voidBlack,
    appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.transparent),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0C2344), Color(0xFF07101E)]),
        borderRadius: BorderRadius.circular(24), border: Border.all(color: SageTheme.cyan.withValues(alpha: .18))),
        child: Row(children: [
          Container(width: 54,height:54,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,color:SageTheme.cyan.withValues(alpha:.1)),child:Icon(widget.icon,color:SageTheme.cyan)),
          const SizedBox(width:16), Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(widget.title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:SageTheme.textPrimary)),const SizedBox(height:5),Text(widget.subtitle,style:const TextStyle(color:SageTheme.textSecondary,fontSize:12,height:1.4))
          ]))
        ])),
      const SizedBox(height:20),
      ...widget.actions.map((a)=>Padding(padding:const EdgeInsets.only(bottom:10),child:FilledButton.tonalIcon(
        onPressed:()=>setState(()=>_message='$a is ready in SAGE ONE.'),
        icon:const Icon(Icons.arrow_forward),label:Align(alignment:Alignment.centerLeft,child:Text(a))))),
      if(_message!=null) ...[const SizedBox(height:18),Text(_message!,style:const TextStyle(color:SageTheme.success,fontWeight:FontWeight.w700))]
    ]));
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.api, super.key});
  final SageApi api;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _messages = <Map<String, String>>[];
  String? _sessionId;
  String? _taskId;
  Timer? _poller;
  bool _sending = false;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _newSession();
  }

  Future<void> _newSession() async {
    try {
      final session = await widget.api.createSession();
      final value = session['session'];
      if (value is Map) _sessionId = value['id']?.toString();
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not start chat');
    }
  }

  Future<void> _loadHistory() async {
    final id = _sessionId;
    if (id == null) return;
    try {
      final items = await widget.api.sessionMessages(id);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(items.whereType<Map>().map((item) => {
                'role': (item['role'] ?? '').toString(),
                'content': (item['content'] ?? '').toString(),
              }));
      });
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (_sessionId == null) await _newSession();
    final sessionId = _sessionId;
    if (sessionId == null) return;

    setState(() {
      _sending = true;
      _status = 'Queued';
      _messages.add({'role': 'user', 'content': text});
      _input.clear();
    });

    try {
      final response = await widget.api.submitCommand(text, sessionId: sessionId);
      final task = response['task'];
      _taskId = task is Map ? task['id']?.toString() : null;
      if (_taskId != null) _startPolling();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _status = 'Could not queue command';
        _messages.add({'role': 'system', 'content': error.toString()});
      });
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _pollTask());
    _pollTask();
  }

  Future<void> _pollTask() async {
    final id = _taskId;
    if (id == null) return;
    try {
      final task = await widget.api.task(id);
      final status = (task['status'] ?? 'unknown').toString().toLowerCase();
      final result = task['result']?.toString();
      final error = task['error']?.toString();
      if (!mounted) return;
      setState(() {
        _status = status.toUpperCase();
        if (status == 'completed' && result != null && result.isNotEmpty) {
          _messages.add({'role': 'assistant', 'content': result});
        } else if (status == 'failed' && error != null) {
          _messages.add({'role': 'system', 'content': error});
        }
        _sending = !{'completed', 'failed', 'cancelled', 'canceled'}.contains(status);
      });
      if (!_sending) {
        _poller?.cancel();
        _loadHistory();
      }
    } catch (_) {}
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
          IconButton(onPressed: _loadHistory, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _newSession, icon: const Icon(Icons.add_comment_outlined)),
        ],
      ),
      body: Column(
        children: [
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
class MarketplaceScreen extends StatelessWidget { const MarketplaceScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Marketplace',subtitle:'Discover services, tools and SAGE-powered work.',icon:Icons.storefront,actions:['Browse marketplace','View saved items','Open seller tools']);}
class JobsScreen extends StatelessWidget { const JobsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Jobs',subtitle:'Work opportunities and execution-ready job workflows.',icon:Icons.work_outline,actions:['Find jobs','Track applications','Open active work']);}
class LearningScreen extends StatelessWidget { const LearningScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Learning',subtitle:'Personal learning paths, progress and AI mentorship.',icon:Icons.school_outlined,actions:['Continue learning','Browse paths','View progress']);}
class CommunityScreen extends StatelessWidget { const CommunityScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Community',subtitle:'Private-first collaboration and future SAGE community spaces.',icon:Icons.groups_outlined,actions:['Open community','Create a post','View activity']);}
class FileManagerScreen extends StatelessWidget { const FileManagerScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'File Manager',subtitle:'Organize SAGE artifacts, project files and exports.',icon:Icons.folder_copy_outlined,actions:['Browse files','Recent artifacts','Export workspace']);}
class AiStudioScreen extends StatelessWidget { const AiStudioScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'AI Studio',subtitle:'Build reusable prompts, agents and execution recipes.',icon:Icons.auto_awesome,actions:['Create a workflow','Prompt library','Agent templates']);}
class SparkWalletScreen extends StatelessWidget { const SparkWalletScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Spark Wallet',subtitle:'SAGE Spark balance and internal work-credit controls.',icon:Icons.account_balance_wallet_outlined,actions:['View Spark balance','Open Spark history','Reserve Spark']);}
class PaymentScreen extends StatelessWidget { const PaymentScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Payments',subtitle:'Payment setup and provider readiness.',icon:Icons.payments_outlined,actions:['Payment methods','Provider status','Payment preferences']);}
class TransactionsScreen extends StatelessWidget { const TransactionsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Transactions',subtitle:'Unified record of work, Spark and payment movements.',icon:Icons.receipt_long_outlined,actions:['View transactions','Filter records','Export records']);}
class ProfileScreen extends StatelessWidget { const ProfileScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Profile',subtitle:'Identity, capabilities and personal SAGE preferences.',icon:Icons.person_outline,actions:['Edit profile','Capabilities','Privacy controls']);}
class SettingsScreen extends StatelessWidget { const SettingsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Settings',subtitle:'Themes, behavior, language and security controls.',icon:Icons.settings_outlined,actions:['Appearance','Language','Security']);}
class NotificationsScreen extends StatelessWidget { const NotificationsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Notifications',subtitle:'Activity, alerts and SAGE execution updates.',icon:Icons.notifications_none,actions:['View notifications','Mark all read','Notification preferences']);}

class KycScreen extends StatelessWidget { const KycScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Identity Verification',subtitle:'KYC readiness with provider-backed verification when configured.',icon:Icons.verified_user_outlined,actions:['Start verification','Check verification status','Review requirements']);}
class FirstRunScreen extends StatelessWidget { const FirstRunScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'First Run',subtitle:'Finish setup and choose how SAGE should work with you.',icon:Icons.flag_outlined,actions:['Complete setup','Choose capabilities','Finish workspace setup']);}
