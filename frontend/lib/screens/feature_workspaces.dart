import 'dart:async';

import 'package:flutter/material.dart';
import '../core/sage_api.dart';
import '../theme/sage_theme.dart';

class FeatureWorkspace extends StatefulWidget {
  const FeatureWorkspace({required this.title, required this.subtitle, required this.icon, required this.actions, super.key});
  final String title, subtitle; final IconData icon; final List<String> actions;
  @override State<FeatureWorkspace> createState() => _FeatureWorkspaceState();
}
class _FeatureWorkspaceState extends State<FeatureWorkspace> {
  Future<void> _explainAction(String action) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: Text(
          '${widget.title} is present in the SAGE ONE interface, but this action is not connected to a live workflow yet. '
          'It will not report success or change account data until its backend integration is implemented.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SageTheme.voidBlack,
    appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.transparent),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0C2344), Color(0xFF07101E)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SageTheme.cyan.withValues(alpha: .18)),
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SageTheme.cyan.withValues(alpha: .1),
            ),
            child: Icon(widget.icon, color: SageTheme.cyan),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: SageTheme.textPrimary,
              )),
              const SizedBox(height: 5),
              Text(widget.subtitle, style: const TextStyle(
                color: SageTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              )),
            ],
          )),
        ]),
      ),
      const SizedBox(height: 20),
      const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline, color: SageTheme.textSecondary),
          title: Text('Integration status'),
          subtitle: Text(
            'Interface available • Live actions not connected yet',
          ),
        ),
      ),
      const SizedBox(height: 12),
      ...widget.actions.map((action) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FilledButton.tonalIcon(
          onPressed: () => _explainAction(action),
          icon: const Icon(Icons.info_outline),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(action),
          ),
        ),
      )),
    ]),
  );
}

enum _ChatRecoveryAction { session, command, history, taskStatus }

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.api, super.key});
  final SageApi api;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const int _maxPollFailures = 5;

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _messages = <Map<String, String>>[];
  String? _sessionId;
  String? _taskId;
  Timer? _poller;
  int _sessionGeneration = 0;
  int _pollFailures = 0;
  bool _pollInFlight = false;
  bool _sending = false;
  String _status = 'Ready';
  String? _chatError;
  _ChatRecoveryAction? _recoveryAction;

  @override
  void initState() {
    super.initState();
    _newSession();
  }

  Future<void> _newSession() async {
    // Invalidate in-flight work before clearing the previous conversation.
    final generation = ++_sessionGeneration;
    _poller?.cancel();
    _pollFailures = 0;
    if (mounted) {
      setState(() {
        _sessionId = null;
        _taskId = null;
        _sending = true;
        _status = 'Starting new session…';
        _chatError = null;
        _recoveryAction = null;
        _messages.clear();
      });
    }
    try {
      final session = await widget.api.createSession();
      final value = session['session'];
      final id = value is Map ? value['id']?.toString() : null;
      if (id == null || id.isEmpty) {
        throw Exception('SAGE did not return a session id.');
      }
      if (!mounted || generation != _sessionGeneration) return;
      setState(() {
        _sessionId = id;
        _sending = false;
        _status = 'Ready';
        _chatError = null;
        _recoveryAction = null;
      });
    } catch (error) {
      if (!mounted || generation != _sessionGeneration) return;
      setState(() {
        _sending = false;
        _status = 'Could not start chat';
        _chatError = 'Could not start chat. Check the API connection, then retry. Details: $error';
        _recoveryAction = _ChatRecoveryAction.session;
      });
    }
  }

  Future<void> _loadHistory({
    required int generation,
    required String sessionId,
  }) async {
    if (generation != _sessionGeneration || sessionId != _sessionId) return;
    try {
      final items = await widget.api.sessionMessages(sessionId);
      if (!mounted ||
          generation != _sessionGeneration ||
          sessionId != _sessionId) {
        return;
      }
      setState(() {
        _messages
          ..clear()
          ..addAll(items.whereType<Map>().map((item) => {
                'role': (item['role'] ?? '').toString(),
                'content': (item['content'] ?? '').toString(),
              }));
        if (_recoveryAction == _ChatRecoveryAction.history) {
          _chatError = null;
          _recoveryAction = null;
          _status = 'Ready';
        }
      });
    } catch (error) {
      if (!mounted ||
          generation != _sessionGeneration ||
          sessionId != _sessionId) {
        return;
      }
      setState(() {
        _status = 'History unavailable';
        _chatError = 'Chat history could not load. Your session is still active. Retry to load it again. Details: $error';
        _recoveryAction = _ChatRecoveryAction.history;
      });
    }
  }

  Future<void> _refreshHistory() async {
    final sessionId = _sessionId;
    if (sessionId == null || _sending) return;
    await _loadHistory(
      generation: _sessionGeneration,
      sessionId: sessionId,
    );
  }

  void _retryRecovery() {
    switch (_recoveryAction) {
      case _ChatRecoveryAction.session:
        _newSession();
        break;
      case _ChatRecoveryAction.command:
        _send();
        break;
      case _ChatRecoveryAction.history:
        _refreshHistory();
        break;
      case _ChatRecoveryAction.taskStatus:
        final sessionId = _sessionId;
        if (sessionId != null && _taskId != null) {
          _startPolling(
            generation: _sessionGeneration,
            sessionId: sessionId,
          );
        }
        break;
      case null:
        return;
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (_sessionId == null) await _newSession();
    final sessionId = _sessionId;
    if (sessionId == null || _sending) return;
    final generation = _sessionGeneration;

    setState(() {
      _sending = true;
      _status = 'Queued';
      _chatError = null;
      _recoveryAction = null;
      _messages.add({'role': 'user', 'content': text});
      _input.clear();
    });

    try {
      final response = await widget.api.submitCommand(text, sessionId: sessionId);
      if (!mounted || generation != _sessionGeneration) return;
      final task = response['task'];
      _taskId = task is Map
          ? (task['id'] ?? task['task_id'])?.toString()
          : response['task_id']?.toString();
      if (_taskId == null || _taskId!.isEmpty) {
        throw Exception('SAGE did not return a task id.');
      }
      _startPolling(generation: generation, sessionId: sessionId);
    } catch (error) {
      if (!mounted || generation != _sessionGeneration) return;
      setState(() {
        if (_messages.isNotEmpty &&
            _messages.last['role'] == 'user' &&
            _messages.last['content'] == text) {
          _messages.removeLast();
        }
        _input.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        _sending = false;
        _status = 'Could not queue command';
        _chatError = 'Command was not queued. Your message has been restored so you can retry. Details: $error';
        _recoveryAction = _ChatRecoveryAction.command;
      });
    }
  }

  void _startPolling({
    required int generation,
    required String sessionId,
  }) {
    _poller?.cancel();
    _pollFailures = 0;
    if (mounted) {
      setState(() {
        _sending = true;
        _status = 'Waiting for task…';
        _chatError = null;
        _recoveryAction = null;
      });
    }
    _poller = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollTask(generation: generation, sessionId: sessionId),
    );
    _pollTask(generation: generation, sessionId: sessionId);
  }

  Future<void> _pollTask({
    required int generation,
    required String sessionId,
  }) async {
    if (generation != _sessionGeneration ||
        sessionId != _sessionId ||
        _pollInFlight) {
      return;
    }
    final id = _taskId;
    if (id == null) return;
    _pollInFlight = true;
    try {
      final task = await widget.api.task(id);
      if (!mounted ||
          generation != _sessionGeneration ||
          sessionId != _sessionId) {
        return;
      }
      final status = (task['status'] ?? 'unknown').toString().toLowerCase();
      final result = task['result']?.toString();
      final error = task['error']?.toString();
      _pollFailures = 0;
      setState(() {
        _chatError = null;
        _recoveryAction = null;
        _status = status.toUpperCase();
        if (status == 'completed' && result != null && result.isNotEmpty) {
          _messages.add({'role': 'assistant', 'content': result});
        } else if (status == 'failed' && error != null && error.isNotEmpty) {
          _messages.add({'role': 'system', 'content': error});
        }
        _sending = !{'completed', 'failed', 'cancelled', 'canceled'}.contains(status);
      });
      if (!_sending) {
        _poller?.cancel();
        await _loadHistory(generation: generation, sessionId: sessionId);
      }
    } catch (error) {
      if (!mounted ||
          generation != _sessionGeneration ||
          sessionId != _sessionId) {
        return;
      }
      _pollFailures++;
      if (_pollFailures >= _maxPollFailures) {
        _poller?.cancel();
        setState(() {
          _status = 'Status check paused';
          _chatError = 'SAGE has not confirmed the task status after $_maxPollFailures attempts. The task may still be running; retry the status check before sending another command. Details: $error';
          _recoveryAction = _ChatRecoveryAction.taskStatus;
        });
      } else {
        setState(() {
          _status = 'Connection issue • retry $_pollFailures/$_maxPollFailures';
        });
      }
    } finally {
      _pollInFlight = false;
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SageTheme.voidBlack,
      appBar: AppBar(
        title: const Text('SAGE Chat'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh chat history',
            onPressed: _sessionId == null || _sending ? null : _refreshHistory,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'New chat session',
            onPressed: _newSession,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_chatError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: SageTheme.failure),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _chatError!,
                          style: const TextStyle(color: SageTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _recoveryAction == null ? null : _retryRecovery,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Talk to SAGE. Every command enters the durable execution pipeline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SageTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final item = _messages[index];
                      final role = item['role'] ?? 'system';
                      final isUser = role == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 620),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser ? SageTheme.blue.withValues(alpha: .24) : SageTheme.cyan.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: SageTheme.cyan.withValues(alpha: .12)),
                          ),
                          child: SelectableText(
                            item['content'] ?? '',
                            style: const TextStyle(color: SageTheme.textPrimary, height: 1.45),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !_sending,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask SAGE to do something…',
                      suffixText: _status,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppsScreen extends StatelessWidget { const AppsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Apps',subtitle:'Connected tools and future integrations in one control surface.',icon:Icons.apps,actions:['Browse connected apps','Connect an app','Manage permissions']);}
class EarningsScreen extends StatelessWidget { const EarningsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Earnings',subtitle:'Track completed work, payouts and creator income.',icon:Icons.trending_up,actions:['View earnings','View pending payouts','Open earnings history']);}
class MarketplaceScreen extends StatelessWidget { const MarketplaceScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Marketplace',subtitle:'Discover services, tools and SAGE-powered work.',icon:Icons.storefront,actions:['Browse marketplace','View saved items','Open seller tools']);}
class JobsScreen extends StatefulWidget {
  const JobsScreen({required this.api, super.key});
  final SageApi api;

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _query = TextEditingController();
  final _location = TextEditingController(text: 'Nepal');
  final _applicationNote = TextEditingController();
  final _postTitle = TextEditingController();
  final _postCompany = TextEditingController();
  final _postDescription = TextEditingController();
  final _postLocation = TextEditingController();
  final _postSalaryMin = TextEditingController();
  final _postSalaryMax = TextEditingController();
  final _postSkills = TextEditingController();
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  String _view = 'find';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    _location.dispose();
    _applicationNote.dispose();
    _postTitle.dispose();
    _postCompany.dispose();
    _postDescription.dispose();
    _postLocation.dispose();
    _postSalaryMin.dispose();
    _postSalaryMax.dispose();
    _postSkills.dispose();
    super.dispose();
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<Map<String, dynamic>> items;
      if (_view == 'applications') {
        final values = await widget.api.myJobApplications();
        items = values.whereType<Map>().map((value) => Map<String, dynamic>.from(value)).toList();
      } else {
        final result = await widget.api.listJobs(
          query: _view == 'find' ? _query.text : null,
          location: _view == 'find' ? _location.text : null,
          mine: _view == 'posts',
          limit: 50,
        );
        final values = result['jobs'];
        items = values is List
            ? values.whereType<Map>().map((value) => Map<String, dynamic>.from(value)).toList()
            : <Map<String, dynamic>>[];
      }
      if (!mounted) return;
      setState(() {
        _items = items;
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

  void _selectView(String view) {
    if (_view == view) return;
    setState(() => _view = view);
    _load();
  }

  String _salary(Map<String, dynamic> job) {
    final low = job['salary_min'];
    final high = job['salary_max'];
    if (low == null && high == null) return 'Salary not specified';
    if (low != null && high != null) return 'NPR $low–$high / month';
    if (low != null) return 'From NPR $low / month';
    return 'Up to NPR $high / month';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SageTheme.voidBlack,
      appBar: AppBar(
        title: const Text('JOBS • NEPAL'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh jobs',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Post a job',
            onPressed: _createJob,
            icon: const Icon(Icons.add_business_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C2344), Color(0xFF07101E)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SageTheme.cyan.withValues(alpha: .2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Find work. Build your future.', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: SageTheme.textPrimary,
                  )),
                  SizedBox(height: 6),
                  Text(
                    'Search opportunities across Nepal or publish a role for your team. Salary ranges are displayed in NPR.',
                    style: TextStyle(color: SageTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Find jobs'),
                  selected: _view == 'find',
                  onSelected: (_) => _selectView('find'),
                ),
                ChoiceChip(
                  label: const Text('My applications'),
                  selected: _view == 'applications',
                  onSelected: (_) => _selectView('applications'),
                ),
                ChoiceChip(
                  label: const Text('My posts'),
                  selected: _view == 'posts',
                  onSelected: (_) => _selectView('posts'),
                ),
              ],
            ),
          ),
          if (_view == 'find')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Role, company or skill',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _location,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _load(),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.place_outlined),
                            labelText: 'Location',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Search jobs',
                        onPressed: _loading ? null : _load,
                        icon: const Icon(Icons.search),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off, size: 36, color: SageTheme.failure),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton.tonalIcon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _items.isEmpty
                        ? _emptyState()
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                              itemCount: _items.length,
                              itemBuilder: (context, index) => _itemCard(_items[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final message = switch (_view) {
      'applications' => 'You have not applied to any jobs yet.',
      'posts' => 'You have not posted any jobs yet. Use the plus button to publish your first opening.',
      _ => 'No jobs matched this search. Try a different role or location, or check again later.',
    };
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(34),
      children: [
        const Icon(Icons.work_outline, size: 42, color: SageTheme.cyan),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: SageTheme.textSecondary)),
      ],
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    final isApplication = _view == 'applications';
    final job = isApplication ? _map(item['job']) : item;
    final title = job['title']?.toString() ?? 'Job opening';
    final company = job['company_name']?.toString() ?? 'Employer';
    final location = job['location']?.toString() ?? 'Nepal';
    final type = (job['employment_type']?.toString() ?? 'full-time').replaceAll('-', ' ');
    final isOwner = job['is_owner'] == true;
    final status = item['status']?.toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_view == 'posts') {
            _showApplicants(job);
          } else if (_view == 'find') {
            _showJob(job);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SageTheme.cyan.withValues(alpha: .1),
                    ),
                    child: const Icon(Icons.work_outline, color: SageTheme.cyan),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(company, style: const TextStyle(color: SageTheme.textSecondary)),
                      ],
                    ),
                  ),
                  if (isApplication && status != null)
                    _statusChip(status)
                  else if (_view == 'posts')
                    _statusChip('${job['application_count'] ?? 0} applicants'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _meta(Icons.place_outlined, location),
                  _meta(Icons.schedule, type),
                  _meta(Icons.payments_outlined, _salary(job)),
                ],
              ),
              if (_view == 'posts') ...[
                const SizedBox(height: 10),
                const Text('Tap to review applicants', style: TextStyle(color: SageTheme.cyan, fontSize: 12)),
              ] else if (_view == 'find' && isOwner) ...[
                const SizedBox(height: 8),
                const Text('Your job post', style: TextStyle(color: SageTheme.cyan, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: SageTheme.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: SageTheme.textSecondary, fontSize: 12)),
        ],
      );

  Widget _statusChip(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: SageTheme.violet.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(status, style: const TextStyle(color: SageTheme.violet, fontSize: 10, fontWeight: FontWeight.w700)),
      );

  Future<void> _showJob(Map<String, dynamic> job) async {
    _applicationNote.clear();
    var busy = false;
    String? errorMessage;
    final applied = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(job['title']?.toString() ?? 'Job details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job['company_name']?.toString() ?? 'Employer', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('${job['location'] ?? 'Nepal'} • ${job['work_mode'] ?? 'on-site'}'),
                const SizedBox(height: 10),
                Text(_salary(job), style: const TextStyle(color: SageTheme.cyan)),
                const SizedBox(height: 12),
                Text(job['description']?.toString() ?? ''),
                if ((job['skills'] as List? ?? const []).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Skills: ${(job['skills'] as List).join(', ')}'),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _applicationNote,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Short note (optional)'),
                  onChanged: (_) => setDialogState(() => errorMessage = null),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMessage!, style: const TextStyle(color: SageTheme.failure)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext, false),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: busy || job['is_owner'] == true
                  ? null
                  : () async {
                      setDialogState(() {
                        busy = true;
                        errorMessage = null;
                      });
                      try {
                        await widget.api.applyToJob(
                          job['id'].toString(),
                          coverNote: _applicationNote.text.trim().isEmpty ? null : _applicationNote.text.trim(),
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                      } catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            busy = false;
                            errorMessage = 'Could not apply: $error';
                          });
                        }
                      }
                    },
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (applied == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted.')));
      if (_view == 'applications') _load();
    }
  }

  Future<void> _showApplicants(Map<String, dynamic> job) async {
    List<Map<String, dynamic>> applicants;
    try {
      final values = await widget.api.jobApplications(job['id'].toString());
      applicants = values.whereType<Map>().map((value) => Map<String, dynamic>.from(value)).toList();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load applicants: $error')));
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Applicants • ${job['title'] ?? 'Job'}'),
          content: SizedBox(
            width: 440,
            child: applicants.isEmpty
                ? const Text('No applications yet.')
                : ListView(
                    shrinkWrap: true,
                    children: applicants.map((application) {
                      final current = application['status']?.toString() ?? 'submitted';
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(application['applicant_name']?.toString() ?? 'SAGE User', style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(application['cover_note']?.toString() ?? 'No note supplied.'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: current,
                                decoration: const InputDecoration(labelText: 'Application status'),
                                items: const [
                                  DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                                  DropdownMenuItem(value: 'reviewing', child: Text('Reviewing')),
                                  DropdownMenuItem(value: 'shortlisted', child: Text('Shortlisted')),
                                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                  DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                                ],
                                onChanged: (value) async {
                                  if (value == null || value == current) return;
                                  try {
                                    await widget.api.updateJobApplicationStatus(
                                      job['id'].toString(),
                                      application['id'].toString(),
                                      value,
                                    );
                                    final index = applicants.indexWhere((item) => item['id'] == application['id']);
                                    if (index >= 0) {
                                      applicants[index] = {...applicants[index], 'status': value};
                                      setDialogState(() {});
                                    }
                                  } catch (error) {
                                    if (dialogContext.mounted) {
                                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                                        SnackBar(content: Text('Could not update application: $error')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Future<void> _createJob() async {
    _postTitle.clear();
    _postCompany.clear();
    _postDescription.clear();
    _postLocation.text = 'Kathmandu, Nepal';
    _postSalaryMin.clear();
    _postSalaryMax.clear();
    _postSkills.clear();
    var employmentType = 'full-time';
    var workMode = 'on-site';
    var busy = false;
    String? errorMessage;
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final canCreate = _postTitle.text.trim().length >= 3 &&
              _postCompany.text.trim().isNotEmpty &&
              _postDescription.text.trim().length >= 20 &&
              _postLocation.text.trim().isNotEmpty &&
              !busy;
          return AlertDialog(
            title: const Text('Post a job'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: _postTitle, onChanged: (_) => setDialogState(() => errorMessage = null), decoration: const InputDecoration(labelText: 'Job title (required)')),
                    TextField(controller: _postCompany, onChanged: (_) => setDialogState(() => errorMessage = null), decoration: const InputDecoration(labelText: 'Company / employer (required)')),
                    TextField(controller: _postDescription, minLines: 3, maxLines: 6, onChanged: (_) => setDialogState(() => errorMessage = null), decoration: const InputDecoration(labelText: 'Description (at least 20 characters)')),
                    TextField(controller: _postLocation, onChanged: (_) => setDialogState(() => errorMessage = null), decoration: const InputDecoration(labelText: 'Location')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: employmentType,
                      decoration: const InputDecoration(labelText: 'Employment type'),
                      items: const [
                        DropdownMenuItem(value: 'full-time', child: Text('Full-time')),
                        DropdownMenuItem(value: 'part-time', child: Text('Part-time')),
                        DropdownMenuItem(value: 'contract', child: Text('Contract')),
                        DropdownMenuItem(value: 'internship', child: Text('Internship')),
                        DropdownMenuItem(value: 'freelance', child: Text('Freelance')),
                      ],
                      onChanged: (value) => setDialogState(() => employmentType = value ?? 'full-time'),
                    ),
                    DropdownButtonFormField<String>(
                      value: workMode,
                      decoration: const InputDecoration(labelText: 'Work mode'),
                      items: const [
                        DropdownMenuItem(value: 'on-site', child: Text('On-site')),
                        DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                        DropdownMenuItem(value: 'remote', child: Text('Remote')),
                      ],
                      onChanged: (value) => setDialogState(() => workMode = value ?? 'on-site'),
                    ),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _postSalaryMin, keyboardType: TextInputType.number, onChanged: (_) => setDialogState(() => errorMessage = null), decoration: const InputDecoration(labelText: 'Min salary (NPR)'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _postSalaryMax, keyboardType: TextInputType.number, onChanged: (_) => setDialogState(() => errorMessage = null), decoration: const InputDecoration(labelText: 'Max salary (NPR)'))),
                      ],
                    ),
                    TextField(controller: _postSkills, decoration: const InputDecoration(labelText: 'Skills (comma separated)')),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(errorMessage!, style: const TextStyle(color: SageTheme.failure)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: canCreate
                    ? () async {
                        final low = int.tryParse(_postSalaryMin.text.trim());
                        final high = int.tryParse(_postSalaryMax.text.trim());
                        if ((_postSalaryMin.text.trim().isNotEmpty && low == null) ||
                            (_postSalaryMax.text.trim().isNotEmpty && high == null) ||
                            (low != null && low < 0) ||
                            (high != null && high < 0) ||
                            (low != null && high != null && high < low)) {
                          setDialogState(() {
                            errorMessage = 'Enter valid non-negative salaries; maximum must not be less than minimum.';
                          });
                          return;
                        }
                        setDialogState(() {
                          busy = true;
                          errorMessage = null;
                        });
                        try {
                          await widget.api.createJob(
                            title: _postTitle.text.trim(),
                            companyName: _postCompany.text.trim(),
                            description: _postDescription.text.trim(),
                            location: _postLocation.text.trim(),
                            employmentType: employmentType,
                            workMode: workMode,
                            salaryMin: low,
                            salaryMax: high,
                            skills: _postSkills.text.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).take(20).toList(),
                          );
                          if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                        } catch (error) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              busy = false;
                              errorMessage = 'Could not create job: $error';
                            });
                          }
                        }
                      }
                    : null,
                child: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Publish job'),
              ),
            ],
          );
        },
      ),
    );
    if (created == true && mounted) {
      setState(() => _view = 'posts');
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job published.')));
    }
  }
}

class LearningScreen extends StatelessWidget { const LearningScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Learning',subtitle:'Personal learning paths, progress and AI mentorship.',icon:Icons.school_outlined,actions:['Continue learning','Browse paths','View progress']);}
class CommunityScreen extends StatelessWidget { const CommunityScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Community',subtitle:'Private-first collaboration and future SAGE community spaces.',icon:Icons.groups_outlined,actions:['Open community','Create a post','View activity']);}
class FileManagerScreen extends StatelessWidget { const FileManagerScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'File Manager',subtitle:'Organize SAGE artifacts, project files and exports.',icon:Icons.folder_copy_outlined,actions:['Browse files','Recent artifacts','Export workspace']);}
class AiStudioScreen extends StatelessWidget { const AiStudioScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'AI Studio',subtitle:'Build reusable prompts, agents and execution recipes.',icon:Icons.auto_awesome,actions:['Create a workflow','Prompt library','Agent templates']);}
class SparkWalletScreen extends StatelessWidget { const SparkWalletScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Spark Wallet',subtitle:'SAGE Spark balance and internal work-credit controls.',icon:Icons.account_balance_wallet_outlined,actions:['View Spark balance','Open Spark history','Reserve Spark']);}
class PaymentScreen extends StatelessWidget { const PaymentScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Payments',subtitle:'Payment setup and provider readiness.',icon:Icons.payments_outlined,actions:['Payment methods','Provider status','Payment preferences']);}
class TransactionsScreen extends StatelessWidget { const TransactionsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Transactions',subtitle:'Unified record of work, Spark and payment movements.',icon:Icons.receipt_long_outlined,actions:['View transactions','Filter records','Export records']);}
class ProfileScreen extends StatelessWidget { const ProfileScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Profile',subtitle:'Identity, capabilities and personal SAGE preferences.',icon:Icons.person_outline,actions:['Edit profile','Capabilities','Privacy controls']);}
class SettingsScreen extends StatelessWidget { const SettingsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Settings',subtitle:'Themes, behavior, language and security controls.',icon:Icons.settings_outlined,actions:['Appearance','Language','Security']);}
class NotificationsScreen extends StatelessWidget { const NotificationsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Notifications',subtitle:'Activity, alerts and SAGE execution updates.',icon:Icons.notifications_none,actions:['View notifications','Mark all read','Notification preferences']);}

class KycScreen extends StatelessWidget { const KycScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Identity Verification',subtitle:'KYC readiness with provider-backed verification when configured.',icon:Icons.verified_user_outlined,actions:['Start verification','Check verification status','Review requirements']);}
class FirstRunScreen extends StatelessWidget { const FirstRunScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'First Run',subtitle:'Finish setup and choose how SAGE should work with you.',icon:Icons.flag_outlined,actions:['Complete setup','Choose capabilities','Finish workspace setup']);}
