import 'package:flutter/material.dart';

import '../core/sage_api.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({required this.api, super.key});
  final SageApi api;
  @override State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late Future<List<dynamic>> _tasks;
  String? _busyTask;

  @override
  void initState() { super.initState(); _reload(); }

  void _reload() { _tasks = widget.api.tasks(); }

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
              const Row(children: [
                Icon(Icons.task_alt), SizedBox(width: 12),
                Text('TASKS', style: TextStyle(
                  fontSize: 11, letterSpacing: 2, color: Colors.white54,
                )),
              ]),
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
                const _Empty(text: 'Unable to load tasks')
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
    final status = '${item['status'] ?? 'unknown'}';
    final cancellable = status == 'queued' || status == 'running' ||
        status == 'claimed' || status == 'processing';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          status == 'completed'
              ? Icons.check_circle_outline
              : status == 'failed'
                  ? Icons.error_outline
                  : Icons.bolt,
        ),
        title: Text(
          '${item['title'] ?? item['task_type'] ?? item['type'] ?? 'Task'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('$status • $id'),
        trailing: cancellable
            ? IconButton(
                tooltip: 'Cancel task',
                onPressed: _busyTask == id ? null : () => _cancel(id),
                icon: Icon(_busyTask == id ? Icons.hourglass_top : Icons.close),
              )
            : null,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(children: [
        const Icon(Icons.inbox_outlined), const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ]),
    ),
  );
}
