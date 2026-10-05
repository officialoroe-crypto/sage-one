import 'package:flutter/material.dart';
import '../theme/sage_theme.dart';

class TaskArtifactScreen extends StatelessWidget {
  const TaskArtifactScreen({required this.title, required this.content, this.kind = 'TEXT', super.key});
  final String title;
  final String content;
  final String kind;

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: SageTheme.voidBlack,
    appBar: AppBar(title: const Text('TASK COMPLETE'), backgroundColor: Colors.transparent),
    body: ListView(padding: const EdgeInsets.all(22), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF102B4A), Color(0xFF07101E)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SageTheme.cyan.withValues(alpha: .28)),
        ),
        child: Row(children: [
          Container(width: 52,height:52,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,color:SageTheme.cyan.withValues(alpha:.1)),child:const Icon(Icons.check_rounded,color:SageTheme.cyan)),
          const SizedBox(width: 15),
          const Expanded(child: Text('Your task is complete.',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800))),
        ]),
      ),
      const SizedBox(height: 18),
      Card(child: Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(kind.toUpperCase(),style:const TextStyle(color:SageTheme.cyan,fontSize:10,letterSpacing:1.8,fontWeight:FontWeight.w800)),
        const SizedBox(height:8),
        Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700)),
        const SizedBox(height:16),
        SelectableText(content,style:const TextStyle(height:1.55,color:SageTheme.textSecondary)),
      ]))),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed:()=>_showFull(context),icon:const Icon(Icons.open_in_new),label:const Text('OPEN ARTIFACT')),
    ]),
  );

  void _showFull(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: SelectableText(content)),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('CLOSE'))],
    ),
  );
}
