import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/sage_api.dart';
import '../theme/sage_theme.dart';
import 'economy.dart';

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
  late final AnimationController _orbAnimation;
  String _status = 'Ready';
  String _provider = 'Cloud routing';
  String _worker = 'Checking worker…';
  String? _taskId;
  dynamic _result;
  bool _sending = false;
  bool _completed = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _orbAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
    _loadRouting();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    try {
      final data = await widget.api.workerHealth();
      final worker = Map<String, dynamic>.from(data['worker'] ?? {});
      if (!mounted) return;
      setState(() => _worker =
          worker['running'] == true ? 'Worker online' : 'Worker offline');
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
      if (mounted) {
        setState(() => _provider = provider?.toString() ?? 'Auto routing');
      }
    } catch (_) {
      if (mounted) setState(() => _provider = 'Offline / unavailable');
    }
  }

  Future<void> _send() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _completed = false;
      _result = null;
      _status = 'SAGE is working…';
    });
    try {
      final response = await widget.api.submitBackground(prompt);
      final taskId = response['task_id'] ?? response['id'];
      if (!mounted) return;
      setState(() {
        _taskId = taskId?.toString();
        _status = _taskId == null ? 'Request accepted' : 'Task queued';
        _prompt.clear();
      });
      if (_taskId != null) {
        _startPolling();
      } else {
        setState(() => _sending = false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _status = 'Could not connect to SAGE Core';
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshTask(),
    );
    _refreshTask();
  }

  Future<void> _refreshTask() async {
    final taskId = _taskId;
    if (taskId == null) return;
    try {
      final task = await widget.api.task(taskId);
      if (!mounted) return;
      final status = (task['status'] ?? 'unknown').toString().toLowerCase();
      final terminal = {'completed', 'failed', 'cancelled', 'canceled'}
          .contains(status);
      final result = task['result'] ?? task['output'] ?? task['error'];
      setState(() {
        _status = status == 'completed'
            ? 'Your task is complete'
            : 'Task ${status.toUpperCase()}';
        _result = result;
        _sending = !terminal;
        _completed = status == 'completed';
      });
      if (terminal) _poller?.cancel();
    } catch (_) {
      if (mounted) setState(() => _status = 'Waiting for SAGE Core…');
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    _prompt.dispose();
    _orbAnimation.dispose();
    super.dispose();
  }

  void _openEconomy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EconomyScreen(api: widget.api)),
    );
  }

  String _resultText() {
    final value = _result;
    if (value == null) return 'SAGE completed the task.';
    if (value is String) return value;
    if (value is Map) {
      for (final key in ['content', 'text', 'summary', 'message', 'result']) {
        final item = value[key];
        if (item is String && item.isNotEmpty) return item;
      }
      return value.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    }
    return value.toString();
  }

  String _resultTitle() {
    final value = _result;
    if (value is Map) {
      for (final key in ['filename', 'file_name', 'name', 'title']) {
        final item = value[key];
        if (item is String && item.isNotEmpty) return item;
      }
    }
    return 'View completed result';
  }

  void _openResult() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SageTheme.surfaceRaised,
        title: Text(_resultTitle()),
        content: SingleChildScrollView(
          child: SelectableText(
            _resultText(),
            style: const TextStyle(height: 1.5, color: SageTheme.textPrimary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    AnimatedBuilder(
                      animation: _orbAnimation,
                      builder: (context, _) => SizedBox(
                        width: 250,
                        height: 250,
                        child: CustomPaint(
                          painter: _StandaloneOrbPainter(
                            intensity: _orbAnimation.value,
                            active: _sending,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _sending ? 'SAGE IS WORKING' : 'SAGE ONE',
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 3.2,
                        fontWeight: FontWeight.w700,
                        color: SageTheme.cyan,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _sending
                          ? 'Working on your request'
                          : 'What would you like me to do?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: SageTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (_completed) ...[
                      const SizedBox(height: 18),
                      _ResultPreview(
                        title: _resultTitle(),
                        onTap: _openResult,
                      ),
                    ],
                    const Spacer(flex: 2),
                    _commandBox(),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatusDot(
                          color: SageTheme.success,
                          label: _worker,
                        ),
                        const SizedBox(width: 16),
                        _StatusDot(
                          color: SageTheme.blue,
                          label: _provider,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAGE ONE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'YOUR PERSONAL AI',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.5,
                  color: SageTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Spark and Evolution',
          onPressed: _openEconomy,
          icon: const Icon(Icons.auto_awesome_outlined),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Icon(Icons.person_outline, size: 19),
        ),
      ],
    );
  }

  Widget _commandBox() {
    return Column(
      children: [
        TextField(
          controller: _prompt,
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _send(),
          decoration: const InputDecoration(
            hintText: 'Message SAGE…',
            prefixIcon: Icon(Icons.chat_bubble_outline, color: SageTheme.cyan),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: Icon(_sending ? Icons.hourglass_top : Icons.arrow_upward),
            label: Text(_sending ? 'Working…' : 'Send to SAGE'),
          ),
        ),
      ],
    );
  }
}

class _ResultPreview extends StatelessWidget {
  const _ResultPreview({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SageTheme.surfaceRaised,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SageTheme.cyan.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: SageTheme.cyan),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.open_in_new, size: 17, color: SageTheme.cyan),
            ],
          ),
        ),
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
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: SageTheme.textSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _StandaloneOrbPainter extends CustomPainter {
  const _StandaloneOrbPainter({
    required this.intensity,
    required this.active,
  });

  final double intensity;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final pulse = active ? 0.72 + intensity * 0.28 : 0.55 + intensity * 0.2;
    final radius = 76.0 + intensity * 3.0;

    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          SageTheme.cyan.withValues(alpha: 0.18 * pulse),
          SageTheme.blue.withValues(alpha: 0.10 * pulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 118));
    canvas.drawCircle(center, 118, outerGlow);

    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.38),
        radius: 0.95,
        colors: [
          const Color(0xFFB8F7FF).withValues(alpha: 0.96),
          SageTheme.cyan.withValues(alpha: 0.96),
          SageTheme.blue.withValues(alpha: 0.94),
          const Color(0xFF101A42),
        ],
        stops: const [0, 0.22, 0.58, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, body);

    final innerLight = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.34 * pulse),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center.translate(-radius * 0.28, -radius * 0.32),
          radius: radius * 0.72,
        ),
      );
    canvas.drawCircle(
      center.translate(-radius * 0.28, -radius * 0.32),
      radius * 0.72,
      innerLight,
    );

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.34 + intensity * 0.18);
    canvas.drawCircle(center, radius, edge);

    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.30 * pulse),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.24),
        ],
        stops: const [0, 0.48, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sheen);
  }

  @override
  bool shouldRepaint(covariant _StandaloneOrbPainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.active != active;
}
