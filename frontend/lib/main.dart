import 'dart:async';

import 'package:flutter/material.dart';

import 'core/sage_api.dart';
import 'screens/agent.dart';
import 'screens/private_owner_gate.dart';
import 'screens/command_center.dart';
import 'screens/create.dart';
import 'screens/project_detail.dart';
import 'screens/projects.dart';
import 'screens/research.dart';
import 'screens/tasks.dart';
import 'screens/world_intelligence.dart';
import 'screens/owner_console.dart';
import 'screens/memory.dart';
import 'theme/sage_theme.dart';

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
      home: _api != null
          ? SageOneShell(api: _api)
          : const PrivateOwnerGate(child: SageOneShell()),
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
