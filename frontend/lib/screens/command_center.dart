import 'dart:async';

import 'package:flutter/material.dart';

import '../core/sage_api.dart';
import '../theme/sage_theme.dart';
class CommandCenter extends StatefulWidget {
  const CommandCenter({required this.api, this.onCreate, super.key});
  final SageApi api;
  final VoidCallback? onCreate;

  @override
  State<CommandCenter> createState() => _CommandCenterState();
}

class _CommandCenterState extends State<CommandCenter>
    with SingleTickerProviderStateMixin {
  final _prompt = TextEditingController();
  String _status = 'Ready';
  String _worker = 'Checking worker…';
  String? _taskId;
  String? _result;
  bool _sending = false;
  Timer? _poller;
  late final AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
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

  Future<void> _send() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _status = 'Sending to SAGE Core…';
    });

    try {
      final result = await widget.api.submitBackground(prompt);
      final taskId = result['task_id'] ?? result['id'];
      if (taskId == null || taskId.toString().isEmpty) {
        throw Exception('SAGE did not return a task id.');
      }
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
      final terminal = {'completed', 'failed', 'cancelled', 'canceled'}.contains(status);

      setState(() {
        _status = terminal ? 'Task complete' : 'SAGE is working…';
        _result = value?.toString();
        _sending = !{'completed', 'failed', 'cancelled', 'canceled'}.contains(status);
      });

      if (!_sending) {
        _poller?.cancel();
        if (status == 'completed' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your task is complete. Open the result below.')),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'Waiting for SAGE Core…');
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    _orbController.dispose();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _orbController,
          builder: (context, _) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                sliver: SliverToBoxAdapter(child: _header()),
              ),
              SliverToBoxAdapter(child: _orbSection()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                sliver: SliverToBoxAdapter(child: _commandBox()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SAGE ONE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.8)),
              SizedBox(height: 3),
              Text('PERSONAL AI • EXECUTION PARTNER', style: TextStyle(fontSize: 8, letterSpacing: 1.2, color: SageTheme.textSecondary)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('STAGE', style: TextStyle(fontSize: 8, letterSpacing: 1.5, color: SageTheme.textSecondary)),
            Text('EVOLUTION', style: TextStyle(fontSize: 9, letterSpacing: 1, color: SageTheme.cyan, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _orbSection() {
    final glow = .55 + (_orbController.value * .45);
    return SizedBox(
      height: 390,
      child: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: CustomPaint(
            painter: _SageOrbPainter(intensity: glow),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('S', style: TextStyle(fontSize: 104, height: .9, fontWeight: FontWeight.w800, color: SageTheme.textPrimary)),
                  SizedBox(height: 14),
                  Text('READY', style: TextStyle(fontSize: 9, letterSpacing: 3, color: SageTheme.cyan, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
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
        const SizedBox(height: 8),
        Center(
          child: Text(
            _worker,
            style: const TextStyle(
              color: SageTheme.textSecondary,
              fontSize: 9,
            ),
          ),
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
}

class _SageOrbPainter extends CustomPainter {
  const _SageOrbPainter({required this.intensity});
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .38;
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          SageTheme.cyan.withValues(alpha: .22 * intensity),
          SageTheme.blue.withValues(alpha: .10 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * .49));
    canvas.drawCircle(center, size.shortestSide * .49, halo);

    final orb = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.25, -.3),
        radius: 1,
        colors: [SageTheme.surfaceRaised, SageTheme.surface, SageTheme.voidBlack],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, orb);

    final softGlow = Paint()
      ..style = PaintingStyle.fill
      ..color = SageTheme.cyan.withValues(alpha: .045 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, radius * .96, softGlow);
  }

  @override
  bool shouldRepaint(covariant _SageOrbPainter oldDelegate) => oldDelegate.intensity != intensity;
}