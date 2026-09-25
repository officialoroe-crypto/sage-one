import 'package:flutter/material.dart';

import '../core/sage_api.dart';
import '../theme/sage_theme.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({required this.api, super.key});
  final SageApi api;

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  static const _types = <String>[
    'fact', 'interest', 'inference', 'skill', 'skill_evidence',
    'goal', 'preference', 'experience',
  ];

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<dynamic> _memories = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.api.profileMemories();
      if (!mounted) return;
      setState(() {
        _memories = items;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _addMemory() async {
    final content = TextEditingController();
    String type = 'fact';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add a memory'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Memory type'),
                  items: _types.map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.replaceAll('_', ' ')),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => type = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: content,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 5000,
                  decoration: const InputDecoration(
                    labelText: 'What should SAGE remember?',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext, content.text.trim().isNotEmpty,
              ),
              child: const Text('Save memory'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || content.text.trim().isEmpty) {
      content.dispose();
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.createProfileMemory(memoryType: type, content: content.text.trim());
      content.dispose();
      await _load();
    } catch (error) {
      content.dispose();
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteMemory(Map item) async {
    final id = item['id']?.toString();
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this memory?'),
        content: const Text('SAGE will no longer keep this saved item. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SageTheme.failure),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.api.deleteProfileMemory(id);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const Row(
              children: [
                Icon(Icons.psychology_alt_outlined, color: SageTheme.cyan),
                SizedBox(width: 12),
                Text('PERSONAL MEMORY', style: TextStyle(
                  fontSize: 11, letterSpacing: 2,
                  color: SageTheme.textSecondary, fontWeight: FontWeight.w800,
                )),
              ],
            ),
            const SizedBox(height: 18),
            const Text('What SAGE remembers', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Review and remove saved details. These memories are private to your profile.',
              style: TextStyle(color: SageTheme.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _addMemory,
                icon: const Icon(Icons.add),
                label: Text(_saving ? 'Saving…' : 'Add memory'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(_error!, style: const TextStyle(color: SageTheme.failure)),
              )),
            ],
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 70),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_memories.isEmpty)
              const Card(child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No saved memories yet. Add one when you want SAGE to remember something.',
                  style: TextStyle(color: SageTheme.textSecondary, height: 1.45)),
              ))
            else
              for (final raw in _memories)
                if (raw is Map)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3, right: 12),
                            child: Icon(Icons.bookmark_outline, color: SageTheme.cyan),
                          ),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (raw['memory_type']?.toString() ?? 'memory').replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(
                                  color: SageTheme.cyan, fontSize: 10,
                                  letterSpacing: 1.3, fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(raw['content']?.toString() ?? '',
                                style: const TextStyle(height: 1.4)),
                              const SizedBox(height: 6),
                              Text(
                                raw['confirmed'] == true ? 'Confirmed' : 'Saved',
                                style: const TextStyle(color: SageTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          )),
                          IconButton(
                            tooltip: 'Delete memory',
                            onPressed: () => _deleteMemory(raw),
                            icon: const Icon(Icons.delete_outline, color: SageTheme.failure),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
