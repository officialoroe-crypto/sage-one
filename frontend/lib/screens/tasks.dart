import 'package:flutter/material.dart';
import '../core/sage_api.dart';
class TasksScreen extends StatefulWidget { const TasksScreen({required this.api,super.key}); final SageApi api; @override State<TasksScreen> createState()=>_TasksScreenState(); }
class _TasksScreenState extends State<TasksScreen> { late Future<List<dynamic>> _tasks;
@override void initState(){super.initState();_tasks=widget.api.tasks();}
@override Widget build(BuildContext context)=>SafeArea(child:RefreshIndicator(onRefresh:()async{setState(()=>_tasks=widget.api.tasks());await _tasks;},child:ListView(padding:const EdgeInsets.fromLTRB(20,24,20,32),children:[
const Row(children:[Icon(Icons.task_alt),SizedBox(width:12),Text('TASKS',style:TextStyle(fontSize:11,letterSpacing:2,color:Colors.white54))]),const SizedBox(height:28),const Text('Execution queue',style:TextStyle(fontSize:25,fontWeight:FontWeight.w700)),const SizedBox(height:8),const Text('Durable work survives the request and is processed by the background worker.',style:TextStyle(color:Colors.white60,height:1.45)),const SizedBox(height:22),
FutureBuilder<List<dynamic>>(future:_tasks,builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError)return const _Empty(text:'Unable to load tasks');final items=s.data??[];if(items.isEmpty)return const _Empty(text:'No queued tasks');return Column(children:items.map((item)=>Card(child:ListTile(leading:const Icon(Icons.bolt),title:Text('${item['task_type']??item['type']??'Task'}'),subtitle:Text('${item['status']??'unknown'} • ${item['id']??item['task_id']??''}')))).toList());})
]))); }
class _Empty extends StatelessWidget { const _Empty({required this.text}); final String text; @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(24),child:Row(children:[const Icon(Icons.inbox_outlined),const SizedBox(width:12),Text(text)]))); }
