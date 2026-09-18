import 'package:flutter/material.dart';
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});
  @override Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), children: [
    const Row(children: [Icon(Icons.folder_open), SizedBox(width: 12), Text('PROJECTS', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.white54))]),
    const SizedBox(height: 28), const Text('Your missions', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8), const Text('Organize work around outcomes, not scattered chats.', style: TextStyle(color: Colors.white60, height: 1.45)),
    const SizedBox(height: 22),
    const _Project(icon: Icons.auto_awesome, title: 'SAGE ONE', detail: 'Personal AI mentor + execution partner', status: 'IN DEVELOPMENT'),
    const _Project(icon: Icons.checkroom, title: 'OROE', detail: 'Clothing brand • wear your essence', status: 'ACTIVE'),
    const _Project(icon: Icons.music_note, title: 'DHUN BARSA MUSIC', detail: 'Music + YouTube creation', status: 'ACTIVE'),
  ]));
}
class _Project extends StatelessWidget {
  const _Project({required this.icon, required this.title, required this.detail, required this.status});
  final IconData icon; final String title, detail, status;
  @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(detail), trailing: Text(status, style: const TextStyle(fontSize: 8, color: Colors.white38))));
}