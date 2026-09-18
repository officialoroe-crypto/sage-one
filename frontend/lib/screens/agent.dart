import 'package:flutter/material.dart';
import '../core/sage_api.dart';

class AgentScreen extends StatelessWidget {
  const AgentScreen({required this.api, super.key});
  final SageApi api;
  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), children: [
    const Row(children: [Icon(Icons.smart_toy_outlined), SizedBox(width: 12), Text('AGENT', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.white54))]),
    const SizedBox(height: 28), const Text('Build. Execute. Verify.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8), const Text('Turn intent into durable work while respecting resource and provider policies.', style: TextStyle(color: Colors.white60, height: 1.45)),
    const SizedBox(height: 22),
    const _Capability(icon: Icons.psychology, title: 'PLAN', detail: 'Break goals into executable work'),
    const _Capability(icon: Icons.cloud_queue, title: 'DELEGATE', detail: 'Route medium and heavy work to cloud'),
    const _Capability(icon: Icons.verified_outlined, title: 'VERIFY', detail: 'Validate outputs before returning results'),
    const _Capability(icon: Icons.memory, title: 'REMEMBER', detail: 'Build durable context over time'),
    const SizedBox(height: 10),
    OutlinedButton.icon(onPressed: () => api.submitBackground('Agent system check'), icon: const Icon(Icons.play_arrow), label: const Text('RUN SYSTEM CHECK')),
  ]));
}
class _Capability extends StatelessWidget {
  const _Capability({required this.icon, required this.title, required this.detail});
  final IconData icon; final String title, detail;
  @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: Icon(icon), title: Text(title, style: const TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700)), subtitle: Text(detail, style: const TextStyle(color: Colors.white54))));
}