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
  bool _loadingHistory = false;
  List<dynamic> _history = <dynamic>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_loadingHistory) return;
    setState(() => _loadingHistory = true);
    try {
      final history = await widget.api.researchHistory(limit: 30);
      if (mounted) setState(() => _history = history);
    } catch (_) {
      // History is additive; a retrieval failure must not block new research.
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

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
      final task = response['task'];
      final taskId = task is Map ? task['id'] : response['task_id'] ?? response['id'];
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
      final taskResponse = await widget.api.task(taskId);
      final task = taskResponse['task'] is Map ? taskResponse['task'] : taskResponse;
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
      if (_isTerminal(status)) {
        _stopPolling();
        await _loadHistory();
      }
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

  Future<void> _openResearch(String researchId) async {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final record = await widget.api.research(researchId);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (record == null) {
        _showMessage('Research report is no longer available.');
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => _ResearchDetail(record: record),
      );
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showMessage('Could not retrieve the research report.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: Text('RESEARCH HISTORY', style: TextStyle(fontSize: 11, letterSpacing: 1.8, fontWeight: FontWeight.w700))),
              IconButton(onPressed: _loadingHistory ? null : _loadHistory, icon: const Icon(Icons.refresh, size: 19)),
            ],
          ),
          if (_history.isEmpty && !_loadingHistory)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('Completed research will appear here.', style: TextStyle(color: Colors.white38)),
            )
          else
            ..._history.map((item) => _HistoryTile(
                  item: item,
                  onTap: () {
                    final id = item is Map ? item['research_id']?.toString() : null;
                    if (id != null) _openResearch(id);
                  },
                )),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap});

  final dynamic item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final map = item is Map ? item : <dynamic, dynamic>{};
    final question = (map['question'] ?? 'Untitled research').toString();
    final summary = (map['summary'] ?? '').toString();
    final sources = (map['source_count'] ?? 0).toString();
    final claims = (map['claim_count'] ?? 0).toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(question, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.35)),
            ],
            const SizedBox(height: 8),
            Text('$sources sources  •  $claims claims', style: const TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: .7)),
          ]),
        ),
      ),
    );
  }
}

class _ResearchDetail extends StatelessWidget {
  const _ResearchDetail({required this.record});

  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) {
    final report = record['report'];
    final reportMap = report is Map ? report : <dynamic, dynamic>{};
    final summary = (reportMap['summary'] ?? record['summary'] ?? '').toString();
    final findings = reportMap['key_findings'];
    final claims = reportMap['claims'];
    final sources = reportMap['sources'];
    return AlertDialog(
      title: const Text('Research report'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record['question']?.toString() ?? 'Research', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            const Text('SUMMARY', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(summary.isEmpty ? 'No summary stored.' : summary),
            if (findings is List && findings.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('KEY FINDINGS', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...findings.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${item.toString()}'),
                  )),
            ],
            if (claims is List && claims.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('CLAIMS + VERIFICATION', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...claims.map((item) => _ClaimRow(item: item)),
            ],
            if (sources is List && sources.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('SOURCES', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...sources.map((item) => Text(item.toString(), style: const TextStyle(color: Colors.white60, fontSize: 12))),
            ],
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))],
    );
  }
}

class _ClaimRow extends StatelessWidget {
  const _ClaimRow({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final map = item is Map ? item : <dynamic, dynamic>{};
    final claim = (map['claim'] ?? item.toString()).toString();
    final status = (map['status'] ?? 'unknown').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(claim),
        const SizedBox(height: 3),
        Text(status.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
      ]),
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
