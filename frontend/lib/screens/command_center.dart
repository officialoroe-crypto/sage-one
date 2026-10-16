import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sage_api.dart';
import '../theme/sage_theme.dart';
import '../widgets/sage_brand_mark.dart';
import 'feature_workspaces.dart';
import 'research.dart';
import 'tasks.dart';
import 'voice_mode.dart';
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
      duration: const Duration(milliseconds: 5200),
    )..repeat();
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

      final statusLabel = switch (status) {
        'completed' => 'Task completed',
        'failed' => 'Task failed',
        'cancelled' || 'canceled' => 'Task cancelled',
        'queued' || 'pending' => 'Task queued',
        'running' || 'processing' || 'in_progress' => 'SAGE is working…',
        _ => 'Task status: $status',
      };

      setState(() {
        _status = statusLabel;
        _result = value?.toString();
        _sending = !terminal;
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                sliver: SliverToBoxAdapter(child: _quickActions()),
              ),
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
    return Row(
      children: [
        const SageBrandMark(size: 46),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAGE ONE',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1.5),
              ),
              SizedBox(height: 3),
              Text(
                'YOUR PERSONAL AI PARTNER',
                style: TextStyle(fontSize: 8, letterSpacing: 1.15, color: SageTheme.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: SageTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: SageTheme.cyan.withValues(alpha: .18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 6, color: _worker == 'Worker online' ? SageTheme.success : SageTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                _worker == 'Worker online' ? 'ONLINE' : 'SAGE CORE',
                style: const TextStyle(fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orbSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR WORKSPACE',
            style: TextStyle(
              color: SageTheme.cyan,
              fontSize: 9,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Good to see you, Nishant.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Bring an idea. SAGE helps you turn it into your next step.',
            style: TextStyle(color: SageTheme.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2344), Color(0xFF07111F), Color(0xFF090D19)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: SageTheme.cyan.withValues(alpha: .22)),
              boxShadow: [
                BoxShadow(
                  color: SageTheme.blue.withValues(alpha: .10),
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 340;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'THINK  •  RESEARCH  •  CREATE',
                            style: TextStyle(
                              color: SageTheme.cyan,
                              fontSize: 8,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 11),
                          Text(
                            'Make your next move count.',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: compact ? 19 : 22,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ask a question or give SAGE a task. You stay in control.',
                            style: TextStyle(color: SageTheme.textSecondary, fontSize: 11, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 16),
                    SageBrandMark(size: compact ? 82 : 106),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _shortcut(
          icon: Icons.chat_bubble_outline,
          title: 'Chat with SAGE',
          subtitle: 'Talk through an idea',
          color: SageTheme.cyan,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ChatScreen(api: widget.api)),
          ),
        ),
        _shortcut(
          icon: Icons.mic_none,
          title: 'Voice',
          subtitle: 'Speak a request',
          color: SageTheme.violet,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => SageVoiceScreen(api: widget.api)),
          ),
        ),
        _shortcut(
          icon: Icons.travel_explore,
          title: 'Research',
          subtitle: 'Explore a question',
          color: SageTheme.blue,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ResearchScreen(api: widget.api)),
          ),
        ),
        _shortcut(
          icon: Icons.task_alt,
          title: 'My tasks',
          subtitle: 'Review task progress',
          color: SageTheme.gold,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => TasksScreen(api: widget.api)),
          ),
        ),
      ],
    );
  }

  Widget _shortcut({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final width = (MediaQuery.sizeOf(context).width - 54) / 2;
    return SizedBox(
      width: width.clamp(132.0, 220.0),
      child: Material(
        color: SageTheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: .20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: SageTheme.textSecondary)),
              ],
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
        const Padding(
          padding: EdgeInsets.only(bottom: 10, top: 12),
          child: Text('WHAT WOULD YOU LIKE TO DO?', style: TextStyle(fontSize: 9, letterSpacing: 1.8, fontWeight: FontWeight.w800, color: SageTheme.textSecondary)),
        ),
        Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.enter) {
              if (HardwareKeyboard.instance.isControlPressed) {
                final selection = _prompt.selection;
                final text = _prompt.text;
                final start = selection.isValid ? selection.start : text.length;
                final end = selection.isValid ? selection.end : text.length;
                _prompt.value = TextEditingValue(
                  text: text.replaceRange(start, end, '\n'),
                  selection: TextSelection.collapsed(offset: start + 1),
                );
                return KeyEventResult.handled;
              }
              _send();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: _prompt,
            minLines: 3,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
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
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SageVoiceScreen(api: widget.api),
              ),
            ),
            icon: const Icon(Icons.mic_none),
            label: const Text('VOICE COMMAND  ·  TAP TO SPEAK'),
            style: OutlinedButton.styleFrom(
              foregroundColor: SageTheme.cyan,
              side: BorderSide(color: SageTheme.cyan.withValues(alpha: .55)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
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

