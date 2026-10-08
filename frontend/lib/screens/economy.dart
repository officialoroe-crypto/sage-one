import 'package:flutter/material.dart';

import '../core/sage_api.dart';
import '../evolution/evolution_visual.dart';

class EconomyScreen extends StatefulWidget {
  const EconomyScreen({required this.api, super.key});
  final SageApi api;
  @override State<EconomyScreen> createState() => _EconomyScreenState();
}

class _EconomyScreenState extends State<EconomyScreen> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _costs = const [];
  List<Map<String, dynamic>> _tiers = const [];
  bool _loading = true;
  String? _error;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait<dynamic>([
        widget.api.economyMe(), widget.api.premiumWorkCosts(), widget.api.evolutionTiers(),
      ]);
      if (!mounted) return;
      final rawCosts = results[1] is Iterable ? results[1] as Iterable : const <dynamic>[];
      final rawTiers = results[2] is Iterable ? results[2] as Iterable : const <dynamic>[];
      setState(() {
        _data = Map<String, dynamic>.from(results[0] as Map);
        _costs = rawCosts.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);
        _tiers = rawTiers.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.toString(); });
    }
  }

  @override Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(
      appBar: AppBar(title: const Text('SAGE Spark')),
      body: _ErrorState(message: _error!, onRetry: _load),
    );
    final spark = _map(_data?['spark']);
    final evolution = _map(_data?['evolution']);
    final ledger = _listMaps(_data?['ledger']);
    final progress = _map(evolution['progress']);
    final achievement = _num(evolution['lifetime_achievement']);
    final ratio = _numDouble(progress['ratio']).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('SAGE Spark'), actions: [
        IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
      ]),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 32), children: [
          _SparkCard(spark: spark),
          const SizedBox(height: 12),
          const _IndependenceCard(),
          const SizedBox(height: 12),
          _EvolutionCard(evolution: evolution, ratio: ratio),
          const SizedBox(height: 22),
          const _SectionTitle('13-STAGE EVOLUTION'),
          const SizedBox(height: 8),
          if (_tiers.isEmpty)
            const Text('Evolution milestones are temporarily unavailable.', style: TextStyle(color: Colors.white54))
          else
            ..._tiers.map((tier) => _TierTile(tier: tier, achievement: achievement, current: evolution['tier']?.toString())),
          const SizedBox(height: 22),
          const _SectionTitle('PREMIUM WORK'),
          const SizedBox(height: 8),
          const Text(
            'Spark is an internal SAGE work credit. Spending Spark never removes verified Evolution achievement.',
            style: TextStyle(color: Colors.white54, height: 1.4, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ..._costs.map((item) => _CostTile(item: item)),
          const SizedBox(height: 22),
          const _SectionTitle('SPARK LEDGER'),
          const SizedBox(height: 8),
          if (ledger.isEmpty)
            const Text('No Spark activity yet.', style: TextStyle(color: Colors.white54))
          else
            ...ledger.map((entry) => _LedgerTile(entry: entry)),
        ]),
      ),
    );
  }

  static Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  static List<Map<String, dynamic>> _listMaps(dynamic value) =>
      value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false) : const [];
  static int _num(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _numDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}

class _SparkCard extends StatelessWidget {
  const _SparkCard({required this.spark});
  final Map<String, dynamic> spark;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFB99CFF).withValues(alpha: .28)),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF19152C), Color(0xFF090E16)]),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFB99CFF).withValues(alpha: .08), border: Border.all(color: const Color(0xFFB99CFF).withValues(alpha: .35))), child: const Icon(Icons.auto_awesome, color: Color(0xFFB99CFF))),
        const SizedBox(width: 12),
        const Expanded(child: Text('SAGE SPARK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
        Text((spark['balance'] ?? 0).toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        _Metric(label: 'Lifetime earned', value: (spark['lifetime_earned'] ?? 0).toString()),
        _Metric(label: 'Lifetime spent', value: (spark['lifetime_spent'] ?? 0).toString()),
      ]),
    ]),
  );
}

class _IndependenceCard extends StatelessWidget {
  const _IndependenceCard();
  @override Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.lock_clock_outlined, color: Color(0xFF7ED7FF)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Evolution is protected', style: TextStyle(fontWeight: FontWeight.w800)),
        SizedBox(height: 4),
        Text('Spark balance changes affect work credits only. Verified lifetime achievement remains independent.', style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.35)),
      ])),
    ])),
  );
}

class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({required this.evolution, required this.ratio});
  final Map<String, dynamic> evolution;
  final double ratio;
  @override Widget build(BuildContext context) {
    final tier = evolution['tier']?.toString() ?? 'Bronze';
    final visual = evolutionVisualFor(tier, intensity: EvolutionIntensity.mid);
    final progress = evolution['progress'] is Map ? Map<String, dynamic>.from(evolution['progress']) : <String, dynamic>{};
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.auto_awesome, color: visual.accent),
        const SizedBox(width: 10),
        const Expanded(child: Text('EVOLUTION', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        Text(tier, style: TextStyle(color: visual.accent, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 10),
      Text((evolution['lifetime_achievement'] ?? 0).toString() + ' verified lifetime achievement', style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: ratio, minHeight: 8, valueColor: AlwaysStoppedAnimation<Color>(visual.accent))),
      const SizedBox(height: 8),
      Row(children: [
        Text((progress['current_threshold'] ?? 0).toString(), style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const Spacer(),
        Text((progress['next_tier'] ?? 'MAX').toString() + '  •  ' + (progress['next_threshold'] ?? 'MAX').toString(), style: TextStyle(color: visual.accent, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    ]));
  }
}

class _TierTile extends StatelessWidget {
  const _TierTile({required this.tier, required this.achievement, required this.current});
  final Map<String, dynamic> tier; final int achievement; final String? current;
  @override Widget build(BuildContext context) {
    final name = tier['tier']?.toString() ?? 'Unknown';
    final threshold = tier['threshold'] is num ? (tier['threshold'] as num).toInt() : 0;
    final visual = evolutionVisualFor(name, intensity: name == current ? EvolutionIntensity.high : EvolutionIntensity.low);
    final reached = achievement >= threshold;
    return Padding(padding: const EdgeInsets.only(bottom: 7), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(color: reached ? visual.accent.withValues(alpha: .07) : Colors.white.withValues(alpha: .018), borderRadius: BorderRadius.circular(15), border: Border.all(color: visual.accent.withValues(alpha: reached ? .34 : .12))),
      child: Row(children: [
        Icon(reached ? Icons.check_circle_outline : Icons.lock_outline, size: 18, color: visual.accent.withValues(alpha: reached ? .95 : .55)),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: TextStyle(fontWeight: name == current ? FontWeight.w800 : FontWeight.w600, color: reached ? Colors.white : Colors.white54))),
        Text(threshold.toString(), style: TextStyle(color: visual.accent.withValues(alpha: .85), fontSize: 11)),
      ]),
    ));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label, value;
  @override Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
    const SizedBox(height: 3),
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
  ]));
}

class _CostTile extends StatelessWidget {
  const _CostTile({required this.item});
  final Map<String, dynamic> item;
  @override Widget build(BuildContext context) => Card(child: ListTile(
    leading: const Icon(Icons.bolt_outlined, color: Color(0xFFB99CFF)),
    title: Text(item['name']?.toString() ?? 'Premium work'),
    subtitle: Text(item['description']?.toString() ?? '', style: const TextStyle(color: Colors.white54)),
    trailing: Text((item['spark_cost'] ?? 0).toString() + ' ✦', style: const TextStyle(fontWeight: FontWeight.w800)),
  ));
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});
  final Map<String, dynamic> entry;
  @override Widget build(BuildContext context) {
    final delta = entry['delta'] is num ? (entry['delta'] as num).toInt() : 0;
    return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(delta >= 0 ? Icons.south_west : Icons.north_east, size: 19),
      title: Text(entry['reason']?.toString() ?? 'Spark activity'),
      subtitle: Text(entry['created_at']?.toString() ?? '', style: const TextStyle(color: Colors.white30, fontSize: 10)),
      trailing: Text((delta >= 0 ? '+' : '') + delta.toString(), style: TextStyle(fontWeight: FontWeight.w800, color: delta >= 0 ? const Color(0xFFE7C76A) : Colors.white70)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: .2));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message; final VoidCallback onRetry;
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.cloud_off, size: 34), const SizedBox(height: 12),
    const Text('SAGE Spark is unavailable right now', style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    const SizedBox(height: 16), OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
  ]));
}
