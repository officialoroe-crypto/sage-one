import 'package:flutter/material.dart';

import '../core/sage_api.dart';
import 'economy.dart';

class CommandCenter extends StatefulWidget {
  const CommandCenter({required this.api, super.key});

  final SageApi api;

  @override
  State<CommandCenter> createState() => _CommandCenterState();
}

class _CommandCenterState extends State<CommandCenter> {
  final _prompt = TextEditingController();
  String _status = 'Ready';
  String _provider = 'Cloud routing';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadRouting();
  }

  Future<void> _loadRouting() async {
    try {
      final data = await widget.api.routing();
      final provider = data['provider'] ?? data['selected_provider'];
      if (!mounted) return;
      setState(() => _provider = provider?.toString() ?? 'Auto routing');
    } catch (_) {
      if (!mounted) return;
      setState(() => _provider = 'Offline / unavailable');
    }
  }

  Future<void> _send() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _status = 'Queued';
    });
    try {
      final result = await widget.api.submitBackground(prompt);
      final taskId = result['task_id'] ?? result['id'];
      if (!mounted) return;
      setState(() {
        _status = taskId == null ? 'Accepted' : 'Task $taskId';
        _prompt.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Connection error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openEconomy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EconomyScreen(api: widget.api)),
    );
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              sliver: SliverToBoxAdapter(child: _header()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverToBoxAdapter(child: _hero()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              sliver: SliverToBoxAdapter(child: _commandBox()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: _modules()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 30),
              sliver: SliverToBoxAdapter(child: _FooterStatus()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: const Icon(Icons.auto_awesome, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SAGE ONE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              SizedBox(height: 2),
              Text('COMMAND CENTER', style: TextStyle(fontSize: 9, letterSpacing: 2.2, color: Colors.white54)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'SAGE Spark & Evolution',
          onPressed: _openEconomy,
          icon: const Icon(Icons.auto_awesome_outlined),
        ),
        const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white10,
          child: Icon(Icons.person_outline, size: 20),
        ),
      ],
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171D25), Color(0xFF0D1117)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are we building today?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.15)),
          SizedBox(height: 10),
          Text('Think it. Give Sage the command. Sage handles the heavy work in the background.', style: TextStyle(color: Colors.white60, height: 1.45)),
        ],
      ),
    );
  }

  Widget _commandBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _prompt,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Tell Sage what you want done…',
            contentPadding: EdgeInsets.all(18),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text(_status, style: const TextStyle(color: Colors.white54, fontSize: 12))),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: Icon(_sending ? Icons.hourglass_top : Icons.arrow_upward),
              label: Text(_sending ? 'Working' : 'Execute'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('ROUTER  •  $_provider', style: const TextStyle(color: Colors.white30, fontSize: 9, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _modules() {
    const modules = [
      ('Research', Icons.travel_explore, 'Search, read, cross-check'),
      ('Tasks', Icons.bolt, 'Queued and running work'),
      ('Projects', Icons.dashboard_customize, 'Your active missions'),
      ('Agent', Icons.smart_toy_outlined, 'Build and execute'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) {
        final (title, icon, subtitle) = modules[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 22),
                  const Spacer(),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.45), fontSize: 11, height: 1.3)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FooterStatus extends StatelessWidget {
  const _FooterStatus();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.circle, size: 8),
        SizedBox(width: 8),
        Text('SAGE CORE', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white54)),
        Spacer(),
        Text('BACKGROUND EXECUTION READY', style: TextStyle(fontSize: 9, letterSpacing: 1.1, color: Colors.white38)),
      ],
    );
  }
}
