import 'package:flutter/material.dart';

import '../core/sage_api.dart';
import '../theme/sage_theme.dart';

class WorldIntelligenceScreen extends StatefulWidget {
  const WorldIntelligenceScreen({required this.api, super.key});

  final SageApi api;

  @override
  State<WorldIntelligenceScreen> createState() => _WorldIntelligenceScreenState();
}

class _WorldIntelligenceScreenState extends State<WorldIntelligenceScreen> {
  Map<String, dynamic>? _status;
  List<dynamic> _knowledge = const [];
  List<dynamic> _due = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        widget.api.worldStatus(),
        widget.api.worldKnowledge(limit: 12),
        widget.api.worldDue(),
      ]);
      if (!mounted) return;
      setState(() {
        _status = results[0] as Map<String, dynamic>;
        _knowledge = results[1] as List<dynamic>;
        _due = results[2] as List<dynamic>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      await widget.api.refreshWorld();
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = (_status?['default_topics'] as List?)?.cast<dynamic>() ?? const [];
    final learning = _status?['learning_enabled'] == true;
    final selfModification = _status?['self_modification'] == true;

    return Scaffold(
      backgroundColor: SageTheme.voidBlack,
      body: SafeArea(
        child: RefreshIndicator(
          color: SageTheme.cyan,
          backgroundColor: SageTheme.surface,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
            children: [
              _header(),
              const SizedBox(height: 18),
              _statusCard(learning, selfModification),
              if (_due.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionHeader('REFRESH NEEDED', Icons.sync_problem),
                const SizedBox(height: 9),
                _topicWrap(_due, accent: SageTheme.gold),
              ],
              const SizedBox(height: 18),
              _sectionHeader('WORLD COVERAGE', Icons.language),
              const SizedBox(height: 9),
              _topicWrap(topics),
              const SizedBox(height: 20),
              _sectionHeader('VERIFIED KNOWLEDGE', Icons.auto_awesome),
              const SizedBox(height: 9),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 44),
                  child: Center(child: CircularProgressIndicator(color: SageTheme.cyan)),
                )
              else if (_error != null)
                _errorCard()
              else if (_knowledge.isEmpty)
                _emptyCard()
              else
                ..._knowledge.map(_knowledgeCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SageTheme.surface,
            border: Border.all(color: SageTheme.cyan.withValues(alpha: .55)),
            boxShadow: [
              BoxShadow(
                color: SageTheme.cyan.withValues(alpha: .12),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.public, color: SageTheme.cyan, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WORLD INTELLIGENCE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              SizedBox(height: 3),
              Text('Public-world learning, source-aware and bounded.', style: TextStyle(fontSize: 10, color: SageTheme.textSecondary)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh world knowledge',
          onPressed: _refreshing ? null : _refresh,
          icon: _refreshing
              ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: SageTheme.cyan))
              : const Icon(Icons.refresh, color: SageTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _statusCard(bool learning, bool selfModification) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: SageTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SageTheme.cyan.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_alt, color: SageTheme.cyan, size: 19),
              SizedBox(width: 9),
              Text('SAGE WORLD LAYER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 14),
          _statusRow('Public-world learning', learning, SageTheme.cyan),
          _statusRow('Source-traceable knowledge', true, SageTheme.success),
          _statusRow('Self-modification blocked', !selfModification, SageTheme.violet),
          _statusRow('Human review for upgrades', true, SageTheme.gold),
        ],
      ),
    );
  }

  Widget _statusRow(String label, bool enabled, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(enabled ? Icons.check_circle_outline : Icons.remove_circle_outline, size: 17, color: accent),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: SageTheme.textPrimary))),
          Text(enabled ? 'ON' : 'OFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17, color: SageTheme.cyan),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: SageTheme.textSecondary)),
      ],
    );
  }

  Widget _topicWrap(List<dynamic> values, {Color accent = SageTheme.blue}) {
    if (values.isEmpty) {
      return const Text('No topics queued.', style: TextStyle(fontSize: 11, color: SageTheme.textSecondary));
    }
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: values.map((value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: accent.withValues(alpha: .22)),
        ),
        child: Text('$value', style: const TextStyle(fontSize: 11, color: SageTheme.textPrimary)),
      )).toList(),
    );
  }

  Widget _knowledgeCard(dynamic item) {
    final data = item is Map ? item : const <String, dynamic>{};
    final topic = data['topic'] ?? 'World knowledge';
    final title = data['title'] ?? data['summary'] ?? 'Knowledge update';
    final sourceCount = data['source_count'] ?? data['sources_count'];
    final updatedAt = data['updated_at'];

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SageTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SageTheme.cyan.withValues(alpha: .10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt, size: 18, color: SageTheme.cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$topic', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SageTheme.cyan)),
                const SizedBox(height: 4),
                Text('$title', style: const TextStyle(fontSize: 13, height: 1.35, color: SageTheme.textPrimary)),
                if (sourceCount != null || updatedAt != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    children: [
                      if (sourceCount != null)
                        Text('$sourceCount sources', style: const TextStyle(fontSize: 10, color: SageTheme.textSecondary)),
                      if (updatedAt != null)
                        Text('$updatedAt', style: const TextStyle(fontSize: 10, color: SageTheme.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SageTheme.failure.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SageTheme.failure.withValues(alpha: .25)),
      ),
      child: Text(_error!, style: const TextStyle(fontSize: 11, color: SageTheme.textSecondary)),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SageTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SageTheme.textSecondary.withValues(alpha: .10)),
      ),
      child: const Text(
        'No world knowledge is persisted yet. Refresh to let the bounded Research OS collect and verify public information.',
        style: TextStyle(fontSize: 11, height: 1.4, color: SageTheme.textSecondary),
      ),
    );
  }
}
