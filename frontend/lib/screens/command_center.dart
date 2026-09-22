import 'dart:async';

import 'package:flutter/material.dart';

import '../core/sage_api.dart';
import '../theme/sage_theme.dart';
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
  String _worker = 'Checking worker…';
  String? _taskId;
  String? _result;
  bool _sending = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _loadRouting();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    try {
      final data = await widget.api.workerHealth();
      final worker = Map<String, dynamic>.from(data['worker'] ?? {});
      if (!mounted) return;
      setState(() {
        _worker = worker['running'] == true ? 'Worker online' : 'Worker offline';
      });
    } catch (_) {
      if (mounted) setState(() => _worker = 'Worker unavailable');
    }
  }

  Future<void> _loadRouting() async {
    try {
      final data = await widget.api.routing();
      final routing = data['routing'];
      final provider = routing is Map
          ? routing['provider']
          : data['provider'] ?? data['selected_provider'];
      if (mounted) setState(() => _provider = provider?.toString() ?? 'Auto routing');
    } catch (_) {
      if (mounted) setState(() => _provider = 'Offline / unavailable');
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
        _taskId = taskId?.toString();
        _status = _taskId == null ? 'Accepted' : 'Queued • $_taskId!';
        _prompt.clear();
      });

      if (_taskId != null) _startPolling();
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Connection error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _refreshTask());
    _refreshTask();
  }

  Future<void> _refreshTask() async {
    final taskId = _taskId;
    if (taskId == null) return;

    try {
      final task = await widget.api.task(taskId);
      if (!mounted) return;
      final status = (task['status'] ?? 'unknown').toString().toLowerCase();
      final value = task['result'] ?? task['error'];

      setState(() {
        _status = 'Task ${status.toUpperCase()} • $taskId';
        _result = value?.toString();
        _sending = !{'completed', 'failed', 'cancelled', 'canceled'}.contains(status);
      });

      if (!_sending) _poller?.cancel();
    } catch (_) {
      if (mounted) setState(() => _status = 'Waiting for SAGE Core…');
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    _prompt.dispose();
    super.dispose();
  }

  void _openEconomy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EconomyScreen(api: widget.api)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              sliver: SliverToBoxAdapter(child: _header()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              sliver: SliverToBoxAdapter(child: _coreSection()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              sliver: SliverToBoxAdapter(child: _commandBox()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              sliver: SliverToBoxAdapter(child: _quickActions()),
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
            color: SageTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: SageTheme.cyan.withValues(alpha: 0.39)),
            boxShadow: [BoxShadow(color: SageTheme.cyan.withValues(alpha: 0.14), blurRadius: 18)],
          ),
          child: const Icon(Icons.auto_awesome, size: 19, color: SageTheme.cyan),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SAGE ONE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
              SizedBox(height: 2),
              Text('PERSONAL AI • EXECUTION PARTNER', style: TextStyle(fontSize: 8, letterSpacing: 1.2, color: SageTheme.textSecondary)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'SAGE Spark & Evolution',
          onPressed: _openEconomy,
          icon: const Icon(Icons.auto_awesome_outlined),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: const Icon(Icons.person_outline, size: 19),
        ),
      ],
    );
  }

  Widget _coreSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: SageTheme.surface.withValues(alpha: 0.71),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SageTheme.cyan.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('COMMAND CENTER', style: TextStyle(fontSize: 9, letterSpacing: 2.2, color: SageTheme.cyan, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 2),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('What are we executing today?', style: TextStyle(fontSize: 23, height: 1.15, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Give SAGE the outcome. Planning, research, execution and verification can run in the background.',
              style: TextStyle(color: SageTheme.textSecondary, fontSize: 12, height: 1.45),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: const Size.square(214), painter: _SageCorePainter()),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('S', style: TextStyle(fontSize: 70, height: .95, fontWeight: FontWeight.w800, color: SageTheme.textPrimary)),
                    SizedBox(height: 5),
                    Text('READY TO EXECUTE', style: TextStyle(fontSize: 8, letterSpacing: 1.8, color: SageTheme.cyan, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatusDot(color: SageTheme.success, label: _worker),
              const SizedBox(width: 14),
              _StatusDot(color: SageTheme.blue, label: _provider),
            ],
          ),
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
            hintText: 'Tell SAGE what you want done…',
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 14, right: 6),
              child: Icon(Icons.bolt, color: SageTheme.cyan),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: EdgeInsets.all(18),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Text(_status, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SageTheme.textSecondary, fontSize: 11))),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: Icon(_sending ? Icons.hourglass_top : Icons.arrow_upward),
              label: Text(_sending ? 'Working' : 'Execute'),
            ),
          ],
        ),
        if (_result != null && _result!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SelectableText(_result!, style: const TextStyle(color: SageTheme.textPrimary, fontSize: 12, height: 1.45)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _quickActions() {
    const modules = [
      ('RESEARCH', Icons.travel_explore, 'Search + verify', SageTheme.cyan),
      ('CREATE', Icons.auto_awesome, 'Build content', SageTheme.violet),
      ('EXECUTE', Icons.bolt, 'Do the work', SageTheme.gold),
    ];

    return Row(
      children: [
        for (var i = 0; i < modules.length; i++) ...[
          Expanded(
            child: _ActionCard(
              title: modules[i].$1,
              subtitle: modules[i].$3,
              icon: modules[i].$2,
              accent: modules[i].$4,
            ),
          ),
          if (i != modules.length - 1) const SizedBox(width: 9),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.accent});

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SageTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.39)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: accent),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: SageTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: SageTheme.textSecondary, fontSize: 9)),
      ],
    );
  }
}

class _SageCorePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);

    final halo = Paint()
      ..shader = RadialGradient(
        colors: [SageTheme.cyan.withValues(alpha: 0.25), SageTheme.blue.withValues(alpha: 0.09), Colors.transparent],
      ).createShader(Rect.fromCircle(center: c, radius: 105));
    canvas.drawCircle(c, 105, halo);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = SageTheme.cyan.withValues(alpha: 0.59);
    canvas.drawCircle(c, 76, ring);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.32);
    canvas.scale(1.65, .38);
    canvas.drawCircle(
      Offset.zero,
      74,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = SageTheme.violet.withValues(alpha: 0.61),
    );
    canvas.restore();

    canvas.drawCircle(c + const Offset(62, -30), 6, Paint()..color = SageTheme.gold);
    canvas.drawCircle(c + const Offset(62, -30), 12, Paint()..color = SageTheme.gold.withValues(alpha: 0.12));

    canvas.drawCircle(
      c,
      53,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.14),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
