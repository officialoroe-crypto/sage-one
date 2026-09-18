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
  String _status = 'Ready for a research question';
  bool _submitting = false;

  Future<void> _submit() async {
    final value = _query.text.trim();
    if (value.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _status = 'Queueing research…';
    });
    try {
      final result = await widget.api.submitBackground('Research: $value');
      final taskId = result['task_id'] ?? result['id'];
      if (!mounted) return;
      setState(() {
        _status = taskId == null ? 'Research queued' : 'Research task: $taskId';
        _query.clear();
      });
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not reach Sage Core');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Text(_status, style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
