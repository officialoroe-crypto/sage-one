import 'dart:async';

import 'package:flutter/material.dart';

import 'core/sage_api.dart';
import 'screens/agent.dart';
import 'screens/auth_gate.dart';
import 'screens/command_center.dart';
import 'screens/projects.dart';
import 'screens/research.dart';
import 'screens/tasks.dart';
import 'screens/world_intelligence.dart';
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
          : AuthGate(
              childBuilder: (_) => const SageOneShell(),
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
    if (widget._api == null) {
      _api.dispose();
    }
    super.dispose();
  }

  Future<void> _refreshNotificationBadge() async {
    try {
      final items = await _api.notifications(unreadOnly: true, limit: 1);
      if (mounted) {
        setState(() => _hasUnreadNotifications = items.isNotEmpty);
      }
    } catch (_) {
      // Notification availability must never block the main navigation shell.
    }
  }

  Future<void> _openTasks() async {
    setState(() => _index = 2);
    try {
      await _api.markAllNotificationsRead();
      if (mounted) setState(() => _hasUnreadNotifications = false);
    } catch (_) {
      // Keep the unread indicator until the server confirms the read operation.
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      CommandCenter(api: _api),
      ResearchScreen(api: _api),
      TasksScreen(api: _api),
      const ProjectsScreen(),
      AgentScreen(api: _api),
      WorldIntelligenceScreen(api: _api),
      OwnerConsoleScreen(api: _api),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) {
              if (value == 2) {
                _openTasks();
              } else {
                setState(() => _index = value);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.auto_awesome),
                label: 'Sage',
              ),
              NavigationDestination(
                icon: Icon(Icons.search),
                label: 'Research',
              ),
              NavigationDestination(
                icon: Icon(Icons.task_alt),
                label: 'Tasks',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_open),
                label: 'Projects',
              ),
              NavigationDestination(
                icon: Icon(Icons.smart_toy_outlined),
                label: 'Agent',
              ),
              NavigationDestination(
                icon: Icon(Icons.public),
                label: 'World',
              ),
              NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                label: 'Owner',
              ),
            ],
          ),
          if (_hasUnreadNotifications)
            Positioned(
              top: 8,
              left: MediaQuery.sizeOf(context).width * 0.5 + 8,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 9, height: 9),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
