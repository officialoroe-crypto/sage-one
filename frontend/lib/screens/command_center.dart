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
  String _status = 'Ready when you are';
  String _worker = 'Connecting to SAGE Core…';
  String? _taskId;
  dynamic _result;
  bool _sending = false;
  bool _completionDialogShown = false;
  Timer? _poller;
  late final AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    try {
      final data = await widget.api.workerHealth();
      final worker = Map<String, dynamic>.from(data['worker'] ?? {});
      if (!mounted) return;
      setState(() {
        _worker = worker['running'] == true
            ? 'SAGE Core is online'
            : 'SAGE Core is currently offline';
      });
    } catch (_) {
      if (mounted) setState(() => _worker = 'SAGE Core status unavailable');
    }
  }

  Future<void> _send() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _completionDialogShown = false;
      _result = null;
      _status = 'Sending your request to SAGE…';
    });

    try {
      final response = await widget.api.submitBackground(prompt);
      final task = response['task'];
      final taskId = response['task_id'] ??
          response['id'] ??
          (task is Map ? task['id'] ?? task['task_id'] : null);
      if (!mounted) return;

      setState(() {
        _taskId = taskId?.toString();
        _status = _taskId == null
            ? 'Request accepted by SAGE'
            : 'SAGE is working on your request';
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
        _status = 'Could not reach SAGE Core';
        _sending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
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
      final result = task['result'] ?? task['error'];

      setState(() {
        _status = switch (status) {
          'completed' => 'Your task is complete',
          'failed' => 'SAGE could not complete this task',
          'cancelled' || 'canceled' => 'Task cancelled',
          'queued' || 'pending' => 'Your task is queued',
          'running' => 'SAGE is working on it…',
          _ => 'SAGE is checking task progress…',
        };
        _result = result;
        _sending = !terminal;
      });

      if (terminal) {
        _poller?.cancel();
        if (status == 'completed' && !_completionDialogShown) {
          _completionDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showCompletion();
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'Waiting for SAGE Core…');
    }
  }

  List<Map<String, dynamic>> _artifacts() {
    final value = _result;
    if (value is! Map) return const [];
    final raw = value['artifacts'] ?? value['files'] ?? value['outputs'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  String _resultText() {
    final value = _result;
    if (value == null) return 'SAGE completed the task.';
    if (value is String) return value;
    if (value is Map) {
      for (final key in ['summary', 'message', 'text', 'content']) {
        final candidate = value[key];
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate;
        }
      }
      return value.entries
          .where((entry) => entry.value is String || entry.value is num)
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n');
    }
    return value.toString();
  }

  void _showCompletion() {
    if (!mounted) return;
    final files = _artifacts();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SageTheme.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: SageTheme.success),
            SizedBox(width: 10),
            Expanded(child: Text('Your task is complete')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _resultText().isEmpty ? 'SAGE completed the task.' : _resultText(),
                  style: const TextStyle(
                    color: SageTheme.textPrimary,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
                if (files.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'YOUR FILES',
                    style: TextStyle(
                      color: SageTheme.cyan,
                      fontSize: 10,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...files.map(_artifactTile),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _artifactTile(Map<String, dynamic> file) {
    final name = (file['name'] ?? file['filename'] ?? file['title'] ?? 'File')
        .toString();
    final location = (file['path'] ?? file['url'] ?? file['uri'] ?? '')
        .toString();
    final type = (file['mime_type'] ?? file['type'] ?? 'FILE').toString();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SageTheme.voidBlack,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SageTheme.cyan.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: SageTheme.cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(location.isEmpty ? type : location,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SageTheme.textSecondary,
                      fontSize: 10,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
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
      body: Stack(
        children: [
          const Positioned.fill(child: _CosmicBackdrop()),
          SafeArea(
            child: AnimatedBuilder(
              animation: _orbController,
              builder: (context, _) => CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
                    sliver: SliverToBoxAdapter(child: _header()),
                  ),
                  SliverToBoxAdapter(child: _orbSection()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    sliver: SliverToBoxAdapter(child: _commandBox()),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.1,
                  color: SageTheme.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'YOUR PERSONAL AI MENTOR',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.55,
                  color: SageTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: SageTheme.surface.withValues(alpha: .8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: SageTheme.cyan.withValues(alpha: .2)),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SageTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _worker.contains('online') ? 'CORE ONLINE' : 'SAGE CORE',
                style: const TextStyle(
                  fontSize: 8,
                  letterSpacing: 1,
                  color: SageTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orbSection() {
    final pulse = Curves.easeInOut.transform(_orbController.value);
    final glow = .55 + pulse * .45;
    return SizedBox(
      height: 390,
      child: Center(
        child: SizedBox(
          width: 292,
          height: 292,
          child: CustomPaint(
            painter: _SageOrbPainter(intensity: glow),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'S',
                    style: TextStyle(
                      fontSize: 112,
                      height: .88,
                      fontWeight: FontWeight.w800,
                      color: SageTheme.textPrimary,
                      shadows: [
                        Shadow(color: SageTheme.cyan, blurRadius: 30),
                        Shadow(color: SageTheme.blue, blurRadius: 52),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _sending ? 'WORKING' : 'READY',
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 3.4,
                      color: SageTheme.cyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
          minLines: 1,
          maxLines: 5,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Tell SAGE what you want done…',
            prefixIcon: const Icon(Icons.bolt, color: SageTheme.cyan),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 17,
            ),
            filled: true,
            fillColor: SageTheme.surface.withValues(alpha: .94),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19),
              borderSide: BorderSide(
                color: SageTheme.cyan.withValues(alpha: .24),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19),
              borderSide: BorderSide(
                color: SageTheme.cyan.withValues(alpha: .2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19),
              borderSide: const BorderSide(color: SageTheme.cyan),
            ),
          ),
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                _status,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SageTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 10),
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
        if (_result != null) ...[
          const SizedBox(height: 14),
          _inlineResult(),
        ],
      ],
    );
  }

  Widget _inlineResult() {
    final files = _artifacts();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: SageTheme.surface.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (_status == 'Your task is complete'
                  ? SageTheme.success
                  : SageTheme.failure)
              .withValues(alpha: .35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _status,
            style: const TextStyle(
              color: SageTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _resultText(),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SageTheme.textSecondary,
              height: 1.4,
              fontSize: 12,
            ),
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...files.map(_artifactTile),
          ],
          if (_status == 'Your task is complete')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showCompletion,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View result'),
              ),
            ),
        ],
      ),
    );
  }
}

class _CosmicBackdrop extends StatelessWidget {
  const _CosmicBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.25),
          radius: 1.25,
          colors: [
            Color(0xFF0A1D35),
            Color(0xFF040B16),
            SageTheme.voidBlack,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _StarFieldPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF9BDFFF).withValues(alpha: .34);
    for (var i = 0; i < 54; i++) {
      final x = ((i * 73 + 19) % 997) / 997 * size.width;
      final y = ((i * 139 + 31) % 991) / 991 * size.height;
      final radius = i % 9 == 0 ? 1.15 : .55;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => false;
}

class _SageOrbPainter extends CustomPainter {
  const _SageOrbPainter({required this.intensity});
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .35;

    // A soft, continuous atmospheric glow only. No orbit, ring, outline or frame.
    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          SageTheme.cyan.withValues(alpha: .23 * intensity),
          SageTheme.blue.withValues(alpha: .13 * intensity),
          const Color(0xFF183BFF).withValues(alpha: .035 * intensity),
          Colors.transparent,
        ],
        stops: const [0, .42, .7, 1],
      ).createShader(Rect.fromCircle(
        center: center,
        radius: size.shortestSide * .5,
      ));
    canvas.drawCircle(center, size.shortestSide * .5, outerGlow);

    final sphere = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.28, -.34),
        radius: .92,
        colors: [
          const Color(0xFF173B65),
          const Color(0xFF07172C),
          const Color(0xFF020713),
          Colors.black,
        ],
        stops: const [0, .38, .78, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sphere);

    final innerLight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.35, -.55),
        radius: .8,
        colors: [
          SageTheme.cyan.withValues(alpha: .14 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, innerLight);
  }

  @override
  bool shouldRepaint(covariant _SageOrbPainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}
