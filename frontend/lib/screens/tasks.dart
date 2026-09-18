import 'dart:async';

import 'package:flutter/material.dart';

import '../core/sage_api.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({required this.api, super.key});
  final SageApi api;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late Future<List<dynamic>> _tasks;
  String? _busyTask;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _reload();
    _poller = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _busyTask == null) setState(_reload);
    });
  }

  void _reload() {
    _tasks = widget.api.tasks();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _tasks;
  }

  Future<void> _cancel(String id) async {
    if (_busyTask != null) return;
    setState(() => _busyTask = id);
    try {
      await widget.api.cancelTask(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task cancelled')),
        );
        setState(_reload);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busyTask = null);
    }
  }

  Future<void> _openTask(dynamic item) async {
    final id = '${item['id'] ?? item['task_id'] ?? ''}';
    if (id.isEmpty) return;
    try {
      final detail = await widget.api.task(id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => _TaskDetail(task: detail),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _tasks,
          builder: (context, snapshot) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              const Row(
                children: [
                  Icon(Icons.task_alt),
                  SizedBox(width: 12),
                  Text('TASKS', style: TextStyle(
                    fontSize: 11, letterSpacing: 2, color: Colors.white54,
                  )),
                ],
              ),
              const SizedBox(height: 28),
              const Text('Execution queue', style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 8),
              const Text(
                'Durable work survives the request and is processed by the background worker.',
                style: TextStyle(color: Colors.white60, height: 1.45),
              ),
              const SizedBox(height: 22),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                _Empty(
                  text: 'Unable to load tasks',
                  action: TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Retry'),
                  ),
                )
              else if ((snapshot.data ?? []).isEmpty)
                const _Empty(text: 'No queued tasks')
              else
                ...snapshot.data!.map(_buildTaskCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(dynamic item) {
    final id = '${item['id'] ?? item['task_id'] ?? ''}';
    final status = '${item['status'] ?? 'unknown'}'.toLowerCase();
    final cancellable = status == 'queued' || status == 'running' ||
        status == 'claimed' || status == 'processing';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _openTask(item),
        leading: _statusIcon(status),
        title: Text(
          '${item['title'] ?? item['task_type'] ?? item['type'] ?? 'Task'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('$status • ${id.isEmpty ? 'no id' : id}'),
        trailing: cancellable
            ? IconButton(
                tooltip: 'Cancel task',
                onPressed: _busyTask == id ? null : () => _cancel(id),
                icon: Icon(_busyTask == id ? Icons.hourglass_top : Icons.close),
              )
            : const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  Icon _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return const Icon(Icons.check_circle_outline);
      case 'failed':
        return const Icon(Icons.error_outline);
      case 'cancelled':
      case 'canceled':
        return const Icon(Icons.cancel_outlined);
      case 'queued':
        return const Icon(Icons.schedule);
      case 'running':
      case 'claimed':
      case 'processing':
        return const Icon(Icons.bolt);
      default:
        return const Icon(Icons.help_outline);
    }
  }
}

class _TaskDetail extends StatelessWidget {
  const _TaskDetail({required this.task});
  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final status = '${task['status'] ?? 'unknown'}';
    final result = task['result'] ?? task['output'];
    final error = task['error'] ?? task['failure_reason'];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              '${task['title'] ?? task['task_type'] ?? task['type'] ?? 'Task'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('STATUS  •  $status', style: const TextStyle(
              fontSize: 10, letterSpacing: 1.4, color: Colors.white54,
            )),
            const SizedBox(height: 18),
            if (task['id'] != null) _DetailRow('Task ID', '${task['id']}'),
            if (task['created_at'] != null)
              _DetailRow('Created', '${task['created_at']}'),
            if (task['updated_at'] != null)
              _DetailRow('Updated', '${task['updated_at']}'),
            if (result != null) _DetailBlock('RESULT', result.toString()),
            if (error != null) _DetailBlock('ERROR', error.toString()),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 72, child: Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 11))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
            fontSize: 10, letterSpacing: 1.2, color: Colors.white54,
          )),
          const SizedBox(height: 8),
          SelectableText(value),
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(children: [
        const Icon(Icons.inbox_outlined),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
        ...[if (action != null) action!],
      ]),
    ),
  );
}
