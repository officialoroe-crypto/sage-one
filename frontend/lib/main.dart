import 'package:flutter/material.dart';

import 'core/sage_api.dart';
import 'screens/command_center.dart';
import 'screens/agent.dart';
import 'screens/projects.dart';
import 'screens/research.dart';
import 'screens/tasks.dart';
import 'theme/sage_theme.dart';

void main() => runApp(const SageOneApp());

class SageOneApp extends StatefulWidget {
  const SageOneApp({SageApi? api, super.key}) : _api = api;
  final SageApi? _api;

  @override
  State<SageOneApp> createState() => _SageOneAppState();
}

class _SageOneAppState extends State<SageOneApp> {
  late final SageApi _api;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _api = widget._api ?? SageApi();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CommandCenter(api: _api, onNavigate: (value) => setState(() => _index = value)),
      ResearchScreen(api: _api),
      TasksScreen(api: _api),
      ProjectsScreen(),
      AgentScreen(api: _api),
    ];
    return MaterialApp(
      title: 'SAGE ONE',
      debugShowCheckedModeBanner: false,
      theme: SageTheme.dark(),
      home: Scaffold(
        body: screens[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Sage'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Research'),
            NavigationDestination(icon: Icon(Icons.task_alt), label: 'Tasks'),
            NavigationDestination(icon: Icon(Icons.folder_open), label: 'Projects'),
            NavigationDestination(icon: Icon(Icons.smart_toy_outlined), label: 'Agent'),
          ],
        ),
      ),
    );
  }
}
