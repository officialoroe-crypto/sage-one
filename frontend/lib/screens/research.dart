import 'package:flutter/material.dart';
import '../core/sage_api.dart';
class ResearchScreen extends StatelessWidget {
  const ResearchScreen({required this.api, super.key}); final SageApi api;
  @override Widget build(BuildContext context)=>SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(20,24,20,32),children:[
    const Row(children:[Icon(Icons.travel_explore),SizedBox(width:12),Text('RESEARCH OS',style:TextStyle(fontSize:11,letterSpacing:2,color:Colors.white54))]),
    const SizedBox(height:28),const Text('Turn a question into evidence.',style:TextStyle(fontSize:25,fontWeight:FontWeight.w700)),
    const SizedBox(height:8),const Text('Search, read, cross-check and preserve evidence before synthesis.',style:TextStyle(color:Colors.white60,height:1.45)),
    const SizedBox(height:22),TextField(decoration:const InputDecoration(hintText:'What should Sage research?'),onSubmitted:(value){if(value.trim().isNotEmpty){api.submitBackground('Research: ${value.trim()}');}}),
    const SizedBox(height:18),const _Stage(label:'SEARCH',detail:'Find relevant sources'),const _Stage(label:'READ + EXTRACT',detail:'Capture useful evidence'),const _Stage(label:'CROSS-CHECK',detail:'Compare sources before synthesis'),const _Stage(label:'SYNTHESIZE',detail:'Produce a cited result'),
  ]));
}
class _Stage extends StatelessWidget { const _Stage({required this.label,required this.detail}); final String label,detail;
@override Widget build(BuildContext context)=>ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.check_circle_outline,size:19),title:Text(label,style:const TextStyle(fontSize:11,letterSpacing:1.3,fontWeight:FontWeight.w700)),subtitle:Text(detail,style:const TextStyle(color:Colors.white45))); }
}
