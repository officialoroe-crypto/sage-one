import 'dart:async';

import 'package:flutter/material.dart';

import '../core/sage_api.dart';
import '../theme/sage_theme.dart';

class CommandCenter extends StatefulWidget {
  const CommandCenter({required this.api, this.onCreate, super.key});
  final SageApi api;
  final VoidCallback? onCreate;
  @override State<CommandCenter> createState() => _CommandCenterState();
}

class _CommandCenterState extends State<CommandCenter> with SingleTickerProviderStateMixin {
  final _prompt = TextEditingController();
  String _status = 'Ready to execute';
  String _worker = 'Checking SAGE Core…';
  String? _taskId;
  String? _result;
  bool _sending = false;
  Timer? _poller;
  late final AnimationController _orbController;

  @override void initState() {
    super.initState();
    _orbController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    try {
      final data = await widget.api.workerHealth();
      final worker = Map<String, dynamic>.from(data['worker'] ?? {});
      if (!mounted) return;
      setState(() => _worker = worker['running'] == true ? 'SAGE Core online' : 'SAGE Core offline');
    } catch (_) {
      if (mounted) setState(() => _worker = 'SAGE Core unavailable');
    }
  }

  Future<void> _send() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty || _sending) return;
    setState(() { _sending = true; _status = 'Sending to SAGE Core…'; _result = null; });
    try {
      final result = await widget.api.submitBackground(prompt);
      final taskId = result['task_id'] ?? result['id'];
      if (!mounted) return;
      setState(() {
        _taskId = taskId?.toString();
        _status = _taskId == null ? 'Accepted by SAGE' : 'Task queued';
        _prompt.clear();
      });
      if (_taskId != null) _startPolling();
    } catch (error) {
      if (!mounted) return;
      setState(() { _status = 'Connection error'; _result = error.toString(); });
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
        _status = terminal ? 'Task ' + status.toUpperCase() : 'SAGE is working • ' + status.toUpperCase();
        _result = value?.toString();
        _sending = !terminal;
      });
      if (terminal) _poller?.cancel();
    } catch (_) {
      if (mounted) setState(() => _status = 'Waiting for SAGE Core…');
    }
  }

  @override void dispose() { _poller?.cancel(); _orbController.dispose(); _prompt.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _orbController,
          builder: (context, _) => CustomScrollView(slivers: [
            SliverPadding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 0), sliver: SliverToBoxAdapter(child: _header())),
            SliverToBoxAdapter(child: _orbSection()),
            SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), sliver: SliverToBoxAdapter(child: _commandPanel())),
          ]),
        ),
      ),
    );
  }

  Widget _header() => Row(children: [
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SAGE ONE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 2)),
      SizedBox(height: 4),
      Text('PERSONAL AI • EXECUTION PARTNER', style: TextStyle(fontSize: 8, letterSpacing: 1.5, color: SageTheme.textSecondary)),
    ])),
    _statusBadge(label: 'EVOLUTION', value: 'ACTIVE', icon: Icons.auto_awesome, color: SageTheme.cyan),
  ]);

  Widget _statusBadge({required String label, required String value, required IconData icon, required Color color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(color: SageTheme.surface.withValues(alpha: .72), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: .20))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color), const SizedBox(width: 7),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(label, style: const TextStyle(fontSize: 7, letterSpacing: 1.2, color: SageTheme.textSecondary)),
        Text(value, style: TextStyle(fontSize: 8, letterSpacing: .8, color: color, fontWeight: FontWeight.w800)),
      ]),
    ]),
  );

  Widget _orbSection() {
    final glow = .55 + (_orbController.value * .45);
    return SizedBox(height: 360, child: Center(child: SizedBox(width: 292, height: 292, child: CustomPaint(
      painter: _SageOrbPainter(intensity: glow),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('S', style: TextStyle(fontSize: 104, height: .9, fontWeight: FontWeight.w800, color: SageTheme.textPrimary)),
        const SizedBox(height: 15),
        Text(_sending ? 'EXECUTING' : 'READY', style: const TextStyle(fontSize: 9, letterSpacing: 3.2, color: SageTheme.cyan, fontWeight: FontWeight.w800)),
      ])),
    ))));
  }

  Widget _commandPanel() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      decoration: BoxDecoration(color: SageTheme.surface.withValues(alpha: .88), borderRadius: BorderRadius.circular(22), border: Border.all(color: SageTheme.cyan.withValues(alpha: .16)), boxShadow: [BoxShadow(color: SageTheme.cyan.withValues(alpha: .035), blurRadius: 30)]),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bolt, size: 15, color: SageTheme.cyan), const SizedBox(width: 7),
          const Text('COMMAND CENTER', style: TextStyle(fontSize: 9, letterSpacing: 1.8, color: SageTheme.cyan, fontWeight: FontWeight.w800)),
          const Spacer(), Text(_worker, style: const TextStyle(fontSize: 8, color: SageTheme.textSecondary)),
        ]),
        const SizedBox(height: 13),
        TextField(
          controller: _prompt, minLines: 2, maxLines: 5,
          decoration: const InputDecoration(hintText: 'Tell SAGE what you want done…', prefixIcon: Padding(padding: EdgeInsets.only(left: 14, right: 6), child: Icon(Icons.auto_awesome, color: SageTheme.cyan)), prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0), contentPadding: EdgeInsets.all(18)),
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(child: Text(_status, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SageTheme.textSecondary, fontSize: 10))),
          const SizedBox(width: 10),
          FilledButton.icon(onPressed: _sending ? null : _send, icon: Icon(_sending ? Icons.hourglass_top : Icons.arrow_upward, size: 17), label: Text(_sending ? 'Working' : 'Execute')),
        ]),
      ]),
    ),
    if (_sending) ...[const SizedBox(height: 12), _executionPulse()],
    if (_result != null && _result!.isNotEmpty) ...[const SizedBox(height: 12), _resultCard()],
  ]);

  Widget _executionPulse() => Container(
    height: 54, padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(color: SageTheme.surface.withValues(alpha: .65), borderRadius: BorderRadius.circular(16), border: Border.all(color: SageTheme.blue.withValues(alpha: .18))),
    child: Row(children: [
      SizedBox(width: 78, child: Row(children: List.generate(7, (index) {
        final phase = (_orbController.value + index / 7) * 3.14;
        final height = 7 + 16 * (0.5 + 0.5 * (phase.sin()));
        return Container(width: 3, height: height, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: SageTheme.cyan.withValues(alpha: .78), borderRadius: BorderRadius.circular(4)));
      }))),
      const SizedBox(width: 5),
      const Expanded(child: Text('SAGE is processing your command through the execution pipeline.', style: TextStyle(fontSize: 9, height: 1.3, color: SageTheme.textSecondary))),
    ]),
  );

  Widget _resultCard() {
    final completed = _status.contains('COMPLETED');
    final accent = completed ? SageTheme.success : SageTheme.failure;
    return Container(
      decoration: BoxDecoration(color: SageTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withValues(alpha: .24))),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(completed ? Icons.task_alt : Icons.error_outline, size: 18, color: accent), const SizedBox(width: 8), Text(completed ? 'YOUR TASK IS COMPLETE' : 'TASK RESULT', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: accent, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: SageTheme.voidBlack.withValues(alpha: .5), borderRadius: BorderRadius.circular(14)), child: SelectableText(_result!, style: const TextStyle(color: SageTheme.textPrimary, fontSize: 12, height: 1.5))),
        if (completed) ...[const SizedBox(height: 11), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.open_in_new, size: 15), label: const Text('OPEN ARTIFACT'))],
      ]),
    );
  }
}

class _SageOrbPainter extends CustomPainter {
  const _SageOrbPainter({required this.intensity});
  final double intensity;
  @override void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .38;
    final halo = Paint()..shader = RadialGradient(colors: [SageTheme.cyan.withValues(alpha: .22 * intensity), SageTheme.blue.withValues(alpha: .10 * intensity), Colors.transparent]).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * .49));
    canvas.drawCircle(center, size.shortestSide * .49, halo);
    final orb = Paint()..shader = const RadialGradient(center: Alignment(-.25, -.3), radius: 1, colors: [SageTheme.surfaceRaised, SageTheme.surface, SageTheme.voidBlack]).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, orb);
    final edge = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = SageTheme.cyan.withValues(alpha: .28 + .18 * intensity);
    canvas.drawCircle(center, radius, edge);
    final glowEdge = Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = SageTheme.cyan.withValues(alpha: .035 * intensity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, radius, glowEdge);
  }
  @override bool shouldRepaint(covariant _SageOrbPainter oldDelegate) => oldDelegate.intensity != intensity;
}