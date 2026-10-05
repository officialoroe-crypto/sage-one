import 'dart:async';

import 'package:flutter/material.dart';

import 'core/sage_api.dart';
import 'screens/agent.dart';
import 'screens/splash.dart';
import 'screens/private_owner_gate.dart';
import 'screens/command_center.dart';
import 'screens/chat.dart' as functional_chat;
import 'screens/voice_listening.dart' as functional_voice;
import 'screens/create.dart';
import 'screens/project_detail.dart';
import 'screens/projects.dart';
import 'screens/research.dart';
import 'screens/tasks.dart';
import 'screens/world_intelligence.dart';
import 'screens/owner_console.dart';
import 'screens/memory.dart';
import 'screens/evolution.dart';
import 'theme/sage_theme.dart';
import 'screens/feature_workspaces.dart';

void main() => runApp(const SageOneApp());

class SageOneApp extends StatelessWidget {
  const SageOneApp({SageApi? api, super.key}) : _api = api;
  final SageApi? _api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAGE ONE',
      debugShowCheckedModeBanner: false,
      theme: SageTheme.dark(),
      home: SageSplashScreen(
        child: _api != null
            ? SageOneShell(api: _api)
            : const PrivateOwnerGate(child: SageOneShell()),
      ),
    );
  }
}

class SageOneShell extends StatefulWidget {
  const SageOneShell({SageApi? api, super.key}) : _api = api;
  final SageApi? _api;

  @override
  State<SageOneShell> createState() => _SageOneShellState();
}

class _SageOneShellState extends State<SageOneShell> {
  late final SageApi _api;
  int _index = 0;
  bool _hasUnreadNotifications = false;
  Timer? _notificationPoller;

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? SageApi();
    _refreshNotificationBadge();
    _notificationPoller = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshNotificationBadge(),
    );
  }

  @override
  void dispose() {
    _notificationPoller?.cancel();
    if (widget._api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _refreshNotificationBadge() async {
    try {
      final items = await _api.notifications(unreadOnly: true, limit: 1);
      if (mounted) setState(() => _hasUnreadNotifications = items.isNotEmpty);
    } catch (_) {}
  }

  Future<void> _openTasks() async {
    setState(() => _index = 2);
    try {
      await _api.markAllNotificationsRead();
      if (mounted) setState(() => _hasUnreadNotifications = false);
    } catch (_) {}
  }

  Future<void> _openMore() async {
    final destination = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: SageTheme.voidBlack,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text('SAGE ONE', style: TextStyle(
                fontSize: 10, letterSpacing: 2,
                color: SageTheme.violet, fontWeight: FontWeight.w800,
              )),
              subtitle: Text('Workspace destinations'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Projects'),
              onTap: () => Navigator.pop(context, 4),
            ),
            ListTile(
              leading: const Icon(Icons.psychology_alt_outlined),
              title: const Text('Memory'),
              onTap: () => Navigator.pop(context, 8),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Evolution'),
              onTap: () => Navigator.pop(context, 9),
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: const Text('Agent'),
              onTap: () => Navigator.pop(context, 5),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('World Intelligence'),
              onTap: () => Navigator.pop(context, 6),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Owner Console'),
              onTap: () => Navigator.pop(context, 7),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Chat'),
              onTap: () => Navigator.pop(context, 10),
            ),
            ListTile(
              leading: const Icon(Icons.mic_none),
              title: const Text('Voice Listening'),
              onTap: () => Navigator.pop(context, 11),
            ),
            ListTile(leading: const Icon(Icons.verified_user_outlined), title: const Text('Identity Verification'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen())); }),
            ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('First Run'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FirstRunScreen())); }),
            ListTile(leading: const Icon(Icons.mic), title: const Text('Voice'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceListeningScreen())); }),
            ListTile(leading: const Icon(Icons.chat_bubble_outline), title: const Text('Chat'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())); }),
            ListTile(leading: const Icon(Icons.apps), title: const Text('Apps'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AppsScreen())); }),
            ListTile(leading: const Icon(Icons.trending_up), title: const Text('Earnings'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen())); }),
            ListTile(leading: const Icon(Icons.storefront), title: const Text('Marketplace'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())); }),
            ListTile(leading: const Icon(Icons.work_outline), title: const Text('Jobs'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsScreen())); }),
            ListTile(leading: const Icon(Icons.school_outlined), title: const Text('Learning'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningScreen())); }),
            ListTile(leading: const Icon(Icons.groups_outlined), title: const Text('Community'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen())); }),
            ListTile(leading: const Icon(Icons.folder_copy_outlined), title: const Text('File Manager'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FileManagerScreen())); }),
            ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('AI Studio'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AiStudioScreen())); }),
            ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('Spark Wallet'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SparkWalletScreen())); }),
            ListTile(leading: const Icon(Icons.payments_outlined), title: const Text('Payments'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())); }),
            ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('Transactions'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen())); }),
            ListTile(leading: const Icon(Icons.person_outline), title: const Text('Profile'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); }),
            ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Settings'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
            ListTile(
              leading: const Icon(Icons.travel_explore),
              title: const Text('Research OS'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 1);
              },
            ),
            ListTile(leading: const Icon(Icons.notifications_none), title: const Text('Notifications'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())); }),

          ],
        ),
      ),
    );
    if (destination != null && mounted) setState(() => _index = destination);
  }

  Future<void> _openProject(Map<String, dynamic> project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(api: _api, project: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      CommandCenter(api: _api, onCreate: () => setState(() => _index = 3)),
      ResearchScreen(api: _api),
      TasksScreen(api: _api),
      CreateScreen(api: _api),
      ProjectsScreen(api: _api, onProjectTap: _openProject),
      AgentScreen(api: _api),
      WorldIntelligenceScreen(api: _api),
      OwnerConsoleScreen(api: _api),
      MemoryScreen(api: _api),
      EvolutionScreen(api: _api),
      functional_chat.ChatScreen(api: _api),
      functional_voice.VoiceListeningScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          NavigationBar(
            selectedIndex: _index > 3 ? 4 : _index,
            onDestinationSelected: (value) {
              if (value == 0) {
                setState(() => _index = 0);
              } else if (value == 1) {
                setState(() => _index = 1);
              } else if (value == 2) {
                _openTasks();
              } else if (value == 3) {
                setState(() => _index = 3);
              } else {
                _openMore();
              }
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Sage'),
              NavigationDestination(icon: Icon(Icons.search), label: 'Research'),
              NavigationDestination(icon: Icon(Icons.task_alt), label: 'Tasks'),
              NavigationDestination(icon: Icon(Icons.auto_awesome_motion), label: 'Create'),
              NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
            ],
          ),
          if (_hasUnreadNotifications)
            Positioned(
              top: 8,
              left: MediaQuery.sizeOf(context).width * 0.5 + 8,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: SizedBox(width: 9, height: 9),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
