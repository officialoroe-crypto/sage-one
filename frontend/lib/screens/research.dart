import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/sage_api.dart';

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({required this.api, super.key});
  final SageApi api;
  @override State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  final _query = TextEditingController();
  Timer? _poller;
  String _status = 'Ready for a research question';
  String? _taskId, _taskStatus, _result, _error;
  bool _submitting = false, _loadingHistory = false;
  String _filter = 'all';
  List<dynamic> _history = <dynamic>[];

  @override void initState() { super.initState(); _loadHistory(); }
  Future<void> _loadHistory() async {
    if (_loadingHistory) return;
    setState(() => _loadingHistory = true);
    try { final history = await widget.api.researchHistory(limit: 30); if (mounted) setState(() => _history = history); }
    catch (_) {} finally { if (mounted) setState(() => _loadingHistory = false); }
  }
  Future<void> _submit() async {
    final value = _query.text.trim();
    if (value.isEmpty || _submitting) return;
    _stopPolling();
    setState(() { _submitting = true; _status = 'Queueing research…'; _taskId = null; _taskStatus = null; _result = null; _error = null; });
    try {
      final response = await widget.api.submitBackground('Research: $value');
      final task = response['task'];
      final id = task is Map ? (task['id'] ?? task['task_id']) : (response['task_id'] ?? response['id']);
      if (!mounted) return;
      setState(() { _taskId = id?.toString(); _taskStatus = _taskId == null ? null : 'queued'; _status = _taskId == null ? 'Research queued' : 'Research is running'; _query.clear(); });
      if (_taskId != null) _startPolling();
    } catch (error) {
      if (mounted) setState(() { _status = 'Could not reach SAGE Core'; _error = error.toString(); });
    } finally { if (mounted) setState(() => _submitting = false); }
  }
  void _startPolling() { _poller?.cancel(); _poller = Timer.periodic(const Duration(seconds: 5), (_) => _refreshTask()); _refreshTask(); }
  Future<void> _refreshTask() async {
    final id = _taskId; if (id == null) return;
    try {
      final response = await widget.api.task(id);
      final task = response['task'] is Map ? response['task'] : response;
      if (!mounted) return;
      final status = (task['status'] ?? 'unknown').toString().toLowerCase();
      setState(() { _taskStatus = status; _status = _friendlyStatus(status); _result = (task['result'] ?? task['output'])?.toString(); _error = (task['error'] ?? task['failure_reason'])?.toString(); });
      if (_isTerminal(status)) { _stopPolling(); await _loadHistory(); }
    } catch (_) { if (mounted) setState(() => _status = 'Waiting for SAGE Core…'); }
  }
  bool _isTerminal(String status) => {'completed','failed','cancelled','canceled'}.contains(status);
  String _friendlyStatus(String status) => switch (status) {
    'queued' => 'Research queued',
    'claimed' || 'running' || 'processing' => 'Research in progress',
    'completed' => 'Research complete',
    'failed' => 'Research failed',
    'cancelled' || 'canceled' => 'Research cancelled',
    _ => 'Research status: $status',
  };
  Future<void> _openResearch(String id) async {
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final record = await widget.api.research(id);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (record == null) { _message('Research report is no longer available.'); return; }
      await showDialog<void>(context: context, builder: (_) => _ResearchDetail(record: record));
    } catch (_) {
      if (mounted) { Navigator.of(context, rootNavigator: true).pop(); _message('Could not retrieve the research report.'); }
    }
  }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _cancel() async {
    final id = _taskId; if (id == null) return;
    try { await widget.api.cancelTask(id); await _refreshTask(); }
    catch (_) { if (mounted) setState(() => _error = 'Could not cancel the research task.'); }
  }
  void _stopPolling() { _poller?.cancel(); _poller = null; }
  @override void dispose() { _stopPolling(); _query.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final active = _taskId != null && (_taskStatus == null || !_isTerminal(_taskStatus!));
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), children: [
      const Row(children: [Icon(Icons.travel_explore), SizedBox(width: 12), Text('RESEARCH OS', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.white54))]),
      const SizedBox(height: 22),
      const Text('Turn a question into evidence.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('SAGE searches, reads, cross-checks and preserves evidence before synthesis.', style: TextStyle(color: Colors.white60, height: 1.45)),
      const SizedBox(height: 18),
      TextField(controller: _query, textInputAction: TextInputAction.search, onSubmitted: (_) => _submit(), decoration: InputDecoration(hintText: 'What should SAGE research?', suffixIcon: IconButton(onPressed: _submitting ? null : _submit, icon: Icon(_submitting ? Icons.hourglass_top : Icons.arrow_upward)))),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: Text(_status, style: const TextStyle(color: Colors.white54, fontSize: 11))), if (active) TextButton.icon(onPressed: _cancel, icon: const Icon(Icons.stop_circle_outlined, size: 16), label: const Text('CANCEL'))]),
      if (_taskId != null) Text('TASK  $_taskId', style: const TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1)),
      if (_result?.isNotEmpty == true) ...[const SizedBox(height: 12), _InfoCard(title: 'RESULT', text: _result!)],
      if (_error?.isNotEmpty == true) ...[const SizedBox(height: 10), _InfoCard(title: 'ERROR', text: _error!)],
      const SizedBox(height: 16), const _ResearchPipeline(), const SizedBox(height: 20),
      Row(children: [
        const Expanded(child: Text('RESEARCH HISTORY', style: TextStyle(fontSize: 11, letterSpacing: 1.8, fontWeight: FontWeight.w700))),
        DropdownButtonHideUnderline(child: DropdownButton<String>(value: _filter, isDense: true, items: const [DropdownMenuItem(value:'all',child:Text('ALL')),DropdownMenuItem(value:'completed',child:Text('DONE')),DropdownMenuItem(value:'failed',child:Text('FAILED'))], onChanged: (v) => setState(() => _filter = v ?? 'all'))),
        IconButton(onPressed: _loadingHistory ? null : _loadHistory, icon: const Icon(Icons.refresh, size: 19)),
      ]),
      if (_history.isEmpty && !_loadingHistory)
        const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('Completed research will appear here.', style: TextStyle(color: Colors.white38)))
      else
        ..._history.where((item) {
          if (_filter == 'all') return true;
          final status = item is Map ? (item['status'] ?? 'completed').toString().toLowerCase() : 'completed';
          return status == _filter;
        }).map((item) => _HistoryTile(item: item, onTap: () { final id = item is Map ? item['research_id']?.toString() : null; if (id != null) _openResearch(id); })),
    ]));
  }
}

class _ResearchPipeline extends StatelessWidget {
  const _ResearchPipeline();
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: const [
    _Stage(label:'SEARCH', detail:'Find relevant public sources'),
    _Stage(label:'READ + EXTRACT', detail:'Capture evidence and source metadata'),
    _Stage(label:'CROSS-CHECK', detail:'Compare claims across sources'),
    _Stage(label:'SYNTHESIZE', detail:'Create a citation-preserving research record'),
  ])));
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap});
  final dynamic item; final VoidCallback onTap;
  @override Widget build(BuildContext context) {
    final map = item is Map ? item : <dynamic,dynamic>{};
    final question = (map['question'] ?? 'Untitled research').toString();
    final summary = (map['summary'] ?? '').toString();
    final sources = (map['source_count'] ?? 0).toString();
    final claims = (map['claim_count'] ?? 0).toString();
    final updated = _relativeDate(map['updated_at'] ?? map['created_at']);
    return Card(margin: const EdgeInsets.only(bottom: 8), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.article_outlined, size: 17), const SizedBox(width: 8), Expanded(child: Text(question, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)))]),
      if (summary.isNotEmpty) ...[const SizedBox(height: 6), Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.35))],
      const SizedBox(height: 8),
      Row(children: [Text('$sources sources  •  $claims claims', style: const TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: .5)), const Spacer(), Text(updated, style: const TextStyle(color: Colors.white30, fontSize: 10))]),
    ])));
  }
  static String _relativeDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? ''); if (date == null) return 'No timestamp';
    final age = DateTime.now().toUtc().difference(date.toUtc());
    if (age.inMinutes < 2) return 'Fresh';
    if (age.inHours < 1) return age.inMinutes.toString() + 'm ago';
    if (age.inHours < 24) return age.inHours.toString() + 'h ago';
    if (age.inDays < 7) return age.inDays.toString() + 'd ago';
    return date.toLocal().toString().split(' ').first;
  }
}

class _ResearchDetail extends StatelessWidget {
  const _ResearchDetail({required this.record});
  final Map<String, dynamic> record;
  @override Widget build(BuildContext context) {
    final report = record['report'] is Map ? Map<String,dynamic>.from(record['report']) : <String,dynamic>{};
    final summary = (report['summary'] ?? record['summary'] ?? '').toString();
    final findings = report['key_findings'] is List ? report['key_findings'] as List : const [];
    final claims = report['claims'] is List ? report['claims'] as List : const [];
    final sources = report['sources'] is List ? report['sources'] as List : const [];
    final verified = claims.where((c) => c is Map && (c['status']?.toString().toLowerCase() == 'verified')).length;
    return AlertDialog(title: const Text('Research report'), content: SizedBox(width: 650, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(record['question']?.toString() ?? 'Research', style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Wrap(spacing: 7, runSpacing: 7, children: [
        _Chip(label: sources.length.toString() + ' sources', icon: Icons.source_outlined),
        _Chip(label: claims.length.toString() + ' claims', icon: Icons.fact_check_outlined),
        _Chip(label: verified.toString() + ' verified', icon: Icons.verified_outlined),
      ]),
      const SizedBox(height: 14),
      const Text('SUMMARY', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6), Text(summary.isEmpty ? 'No summary stored.' : summary),
      if (findings.isNotEmpty) ...[const SizedBox(height: 14), const Text('KEY FINDINGS', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)), const SizedBox(height: 6), ...findings.map((item) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• ' + item.toString())))],
      if (claims.isNotEmpty) ...[const SizedBox(height: 14), const Text('CLAIMS + VERIFICATION', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)), const SizedBox(height: 6), ...claims.map((item) => _ClaimRow(item: item))],
      if (sources.isNotEmpty) ...[const SizedBox(height: 14), const Text('SOURCES', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)), const SizedBox(height: 6), ...sources.map((item) => _SourceRow(item: item))],
    ]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))]);
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.item});
  final dynamic item;
  @override Widget build(BuildContext context) {
    final map = item is Map ? item : <dynamic,dynamic>{};
    final title = (map['title'] ?? map['name'] ?? map['url'] ?? item.toString()).toString();
    final url = map['url']?.toString();
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: ListTile(contentPadding: EdgeInsets.zero, dense: true,
      leading: const Icon(Icons.link, size: 18), title: Text(title, style: const TextStyle(fontSize: 12)),
      subtitle: Text((map['published_at'] ?? map['accessed_at'] ?? '').toString(), style: const TextStyle(color: Colors.white30, fontSize: 10)),
      onTap: url == null ? null : () async { final uri = Uri.tryParse(url); if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return; await launchUrl(uri, mode: LaunchMode.externalApplication); }));
  }
}
class _ClaimRow extends StatelessWidget {
  const _ClaimRow({required this.item}); final dynamic item;
  @override Widget build(BuildContext context) {
    final map = item is Map ? item : <dynamic,dynamic>{};
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text((map['claim'] ?? item.toString()).toString()), const SizedBox(height: 3),
      Text((map['status'] ?? 'unknown').toString().toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
    ]));
  }
}
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon}); final String label; final IconData icon;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .04), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 10))]));
}
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.text}); final String title, text;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(text, style: const TextStyle(color: Colors.white70, height: 1.4))])));
}
class _Stage extends StatelessWidget {
  const _Stage({required this.label, required this.detail}); final String label, detail;
  @override Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle_outline, size: 19), title: Text(label, style: const TextStyle(fontSize: 11, letterSpacing: 1.3, fontWeight: FontWeight.w700)), subtitle: Text(detail, style: const TextStyle(color: Colors.white38)));
}
