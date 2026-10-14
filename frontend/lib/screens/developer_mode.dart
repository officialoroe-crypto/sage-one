import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/sage_api.dart';
import '../theme/sage_theme.dart';

class DeveloperModeScreen extends StatefulWidget {
  const DeveloperModeScreen({required this.api, super.key});

  final SageApi api;

  @override
  State<DeveloperModeScreen> createState() => _DeveloperModeScreenState();
}

class _DeveloperModeScreenState extends State<DeveloperModeScreen> {
  final _taskController = TextEditingController();
  final _workspaceController = TextEditingController();
  Map<String, dynamic>? _proposal;
  String? _proposalId;
  String? _status;
  bool _loading = false;
  bool _applying = false;

  Future<void> _preview() async {
    final task = _taskController.text.trim();
    if (task.isEmpty || _loading || _applying) return;
    setState(() {
      _loading = true;
      _status = 'Inspecting workspace…';
      _proposal = null;
      _proposalId = null;
    });
    try {
      final response = await widget.api.developerPreview(
        task,
        workspace: _workspaceController.text.trim().isEmpty
            ? null
            : _workspaceController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _proposal = response['proposal'] is Map
            ? Map<String, dynamic>.from(response['proposal'] as Map)
            : response;
        _proposalId = response['proposal_id']?.toString();
        _status = response['requires_approval'] == true
            ? 'Preview ready — nothing has been changed.'
            : 'Preview returned without an approval gate.';
      });
    } catch (error) {
      if (mounted) setState(() => _status = 'Preview failed: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apply() async {
    final proposalId = _proposalId;
    if (proposalId == null || _applying) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve code change?'),
        content: const Text(
          'SAGE will apply exactly this previously previewed proposal. '
          'This is a real workspace mutation and cannot be silently approved.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Approve & Apply')),
        ],
      ),
    );
    if (approved != true) return;

    setState(() {
      _applying = true;
      _status = 'Applying approved proposal…';
    });
    try {
      final response = await widget.api.developerApply(proposalId, approved: true);
      if (!mounted) return;
      setState(() {
        _status = response['success'] == true
            ? 'Applied the exact approved preview successfully.'
            : 'Apply finished with a failure.';
        _proposal = response;
        _proposalId = null;
      });
    } catch (error) {
      if (mounted) setState(() => _status = 'Apply failed: $error');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Widget _proposalDetails() {
    final proposal = _proposal ?? const <String, dynamic>{};
    final rawChanges = proposal['changes'];
    if (rawChanges is! List || rawChanges.isEmpty) {
      return SelectableText(
        const JsonEncoder.withIndent('  ').convert(proposal),
        style: const TextStyle(color: SageTheme.textPrimary, fontSize: 12, height: 1.4),
      );
    }

    String excerpt(dynamic value) {
      final text = value?.toString() ?? '(new file)';
      return text.length > 6000
          ? '${text.substring(0, 6000)}\n… preview truncated for readability …'
          : text;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          proposal['response']?.toString() ?? 'Proposed file changes',
          style: const TextStyle(color: SageTheme.textPrimary, height: 1.4),
        ),
        const SizedBox(height: 10),
        Text(
          '${rawChanges.length} file change(s) · isolated preview · nothing applied yet',
          style: const TextStyle(color: SageTheme.cyan, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        for (final raw in rawChanges)
          if (raw is Map) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SageTheme.voidBlack,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SageTheme.cyan.withValues(alpha: .16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    raw['path']?.toString() ?? 'Unknown file',
                    style: const TextStyle(color: SageTheme.cyan, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  const Text('BEFORE', style: TextStyle(color: SageTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  SelectableText(
                    excerpt(raw['before_content']),
                    style: const TextStyle(color: SageTheme.textSecondary, fontFamily: 'monospace', fontSize: 11, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  const Text('PROPOSED', style: TextStyle(color: SageTheme.cyan, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  SelectableText(
                    excerpt(raw['content']),
                    style: const TextStyle(color: SageTheme.textPrimary, fontFamily: 'monospace', fontSize: 11, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canApply = _proposalId != null && !_loading && !_applying;
    return Scaffold(
      backgroundColor: SageTheme.voidBlack,
      appBar: AppBar(
        title: const Text('Developer Mode'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SageTheme.violet.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SageTheme.violet.withValues(alpha: .22)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings_outlined, color: SageTheme.violet),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Owner-only coding control. Preview is non-mutating. '
                    'Apply always requires an explicit approval action.',
                    style: TextStyle(color: SageTheme.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _taskController,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'What should SAGE change?',
              hintText: 'Example: Add a retry state to the task result card.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _workspaceController,
            decoration: const InputDecoration(
              labelText: 'Workspace (optional)',
              hintText: 'Uses the configured SAGE workspace when blank.',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading || _applying ? null : _preview,
              icon: const Icon(Icons.visibility_outlined),
              label: Text(_loading ? 'Inspecting…' : 'Preview change'),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 14),
            Text(_status!, style: const TextStyle(color: SageTheme.textSecondary)),
          ],
          if (_proposal != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SageTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SageTheme.cyan.withValues(alpha: .14)),
              ),
              child: _proposalDetails(),

            ),
            if (_proposalId != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canApply ? _apply : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(_applying ? 'Applying…' : 'Approve & Apply'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
