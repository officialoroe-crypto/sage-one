import 'dart:async';

import 'package:flutter/material.dart';

import '../core/sage_api.dart';

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({required this.api, super.key});

  final SageApi api;

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  final _query = TextEditingController();
  Timer? _poller;
  String _status = 'Ready for a research question';
  String? _taskId;
  String? _taskStatus;
  String? _result;
  String? _error;
  bool _submitting = false;

  Future<void> _submit() async {
    final value = _query.text.trim();
    if (value.isEmpty || _submitting) return;
    _stopPolling();
    setState(() {
      _submitting = true;
      _status = 'Queueing research…';
      _taskId = null;
      _taskStatus = null;
      _result = null;
      _error = null;
    });
    try {
      final response = await widget.api.submitBackground('Research: $value');
      final taskId = response['task_id'] ?? response['id'];
      if (!mounted) return;
      setState(() {
        _taskId = taskId?.toString();
        _taskStatus = _taskId == null ? null : 'queued';
        _status = _taskId == null ? 'Research queued' : 'Research is running';
        _query.clear();
      });
      if (_taskId != null) _startPolling();
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = 'Could not reach Sage Core';
          _error = 'The research task could not be queued.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _startPolling() {
    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _refreshTask());
    _refreshTask();
  }

  Future<void> _refreshTask() async {
    final taskId = _taskId;
    if (taskId == null) return;
    try {
      final task = await widget.api.task(taskId);
      if (!mounted) return;
      final status = (task['status'] ?? 'unknown').toString().toLowerCase();
      final result = task['result'] ?? task['output'];
      final failure = task['error'] ?? task['failure_reason'];
      setState(() {
        _taskStatus = status;
        _status = _friendlyStatus(status);
        _result = result?.toString();
        _error = failure?.toString();
      });
      if (_isTerminal(status)) _stopPolling();
    } catch (_) {
      if (mounted) setState(() => _status = 'Waiting for Sage Core…');
    }
  }

  bool _isTerminal(String status) {
    return status == 'completed' ||
        status == 'failed' ||
        status == 'cancelled' ||
        status == 'canceled';
  }

  String _friendlyStatus(String status) {
    switch (status) {
      case 'queued':
        return 'Research queued';
      case 'claimed':
      case 'running':
      case 'processing':
        return 'Research in progress';
      case 'completed':
        return 'Research complete';
      case 'failed':
        return 'Research failed';
      case 'cancelled':
      case 'canceled':
        return 'Research cancelled';
      default:
        return 'Research status: $status';
    }
  }

  Future<void> _cancel() async {
    final taskId = _taskId;
    if (taskId == null) return;
    try {
      await widget.api.cancelTask(taskId);
      await _refreshTask();
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not cancel the research task.');
    }
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  @override
  void dispose() {
    _stopPolling();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _taskId != null &&
        (_taskStatus == null || !_isTerminal(_taskStatus!));
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const Row(children: [
            Icon(Icons.travel_explore),
            SizedBox(width: 12),
            Text('RESEARCH OS', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.white54)),
          ]),
          const SizedBox(height: 28),
          const Text('Turn a question into evidence.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Search, read, cross-check and preserve evidence before synthesis.', style: TextStyle(color: Colors.white60, height: 1.45)),
          const SizedBox(height: 22),
          TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'What should Sage research?',
              suffixIcon: IconButton(
                onPressed: _submitting ? null : _submit,
                icon: Icon(_submitting ? Icons.hourglass_top : Icons.arrow_upward),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(_status, style: const TextStyle(color: Colors.white54, fontSize: 11))),
              if (active)
                TextButton.icon(
                  onPressed: _cancel,
                  icon: const Icon(Icons.stop_circle_outlined, size: 16),
                  label: const Text('CANCEL'),
                ),
            ],
          ),
          if (_taskId != null)
            Text('TASK  $_taskId', style: const TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1)),
          if (_result != null && _result!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _InfoCard(title: 'RESULT', text: _result!),
          ],
          if (_error != null && _error!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoCard(title: 'ERROR', text: _error!),
          ],
          const SizedBox(height: 18),
          const _Stage(label: 'SEARCH', detail: 'Find relevant sources'),
          const _Stage(label: 'READ + EXTRACT', detail: 'Capture useful evidence'),
          const _Stage(label: 'CROSS-CHECK', detail: 'Compare sources before synthesis'),
          const _Stage(label: 'SYNTHESIZE', detail: 'Produce a cited result'),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white70, height: 1.4)),
        ]),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle_outline, size: 19),
      title: Text(label, style: const TextStyle(fontSize: 11, letterSpacing: 1.3, fontWeight: FontWeight.w700)),
      subtitle: Text(detail, style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.45))),
    );
  }
}
