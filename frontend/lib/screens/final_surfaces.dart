// ignore_for_file: prefer_interpolation_to_compose_strings, empty_catches
import 'package:flutter/material.dart';
import '../core/sage_api.dart';
import '../theme/sage_theme.dart';

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.body});
  final String title; final Widget body;
  @override Widget build(BuildContext c)=>Scaffold(
    backgroundColor:SageTheme.voidBlack,
    appBar:AppBar(title:Text(title),backgroundColor:Colors.transparent),
    body:body,
  );
}

class SparkWalletScreen extends StatefulWidget {
  const SparkWalletScreen({required this.api,super.key}); final SageApi api;
  @override State<SparkWalletScreen> createState()=>_SparkWalletState();
}
class _SparkWalletState extends State<SparkWalletScreen>{
  Map<String,dynamic>? data; Object? error;
  Future<void> load()async{try{final v=await widget.api.economyMe();if(mounted)setState(()=>data=v);}catch(e){if(mounted)setState(()=>error=e);}}
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext c)=>_Page(title:'Spark Wallet',body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[
    if(error!=null)Text('Wallet error: '+error.toString(),style:const TextStyle(color:SageTheme.textSecondary)),
    if(data!=null)...[
      _row('Balance',data!['spark']?['balance']),
      _row('Lifetime earned',data!['spark']?['lifetime_earned']),
      _row('Lifetime spent',data!['spark']?['lifetime_spent']),
      const SizedBox(height:20),const Text('Spark ledger',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
      ...(data!['ledger'] is List?data!['ledger'] as List:const []).map((e)=>ListTile(
        title:Text(e['reason']?.toString()??'Spark movement'),
        subtitle:Text(e['created_at']?.toString()??''),
        trailing:Text(e['delta']?.toString()??'0'),
      )),
    ] else if(error==null)const Center(child:CircularProgressIndicator()),
  ])));
  Widget _row(String a,d)=>Card(child:ListTile(title:Text(a),trailing:Text((d??0).toString(),style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:SageTheme.cyan))));
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({required this.api,super.key}); final SageApi api;
  @override State<TransactionsScreen> createState()=>_TransactionsState();
}
class _TransactionsState extends State<TransactionsScreen>{
  List items=[]; Object? error;
  Future<void> load()async{try{final d=await widget.api.economyMe();if(mounted)setState(()=>items=d['ledger'] is List?d['ledger']:[]);}catch(e){if(mounted)setState(()=>error=e);}}
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext c)=>_Page(title:'Transactions',body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[
    if(error!=null)Text('Transaction error: '+error.toString()),
    ...items.map((e)=>Card(child:ListTile(title:Text(e['reason']?.toString()??'Spark movement'),subtitle:Text(e['reference']?.toString()??e['created_at']?.toString()??''),trailing:Text(e['delta']?.toString()??'0')))),
    if(items.isEmpty&&error==null)const Padding(padding:EdgeInsets.all(40),child:Text('No Spark transactions yet.')),
  ])));
}

class EvolutionFinalScreen extends StatefulWidget {
  const EvolutionFinalScreen({required this.api,super.key}); final SageApi api;
  @override State<EvolutionFinalScreen> createState()=>_EvolutionFinalState();
}
class _EvolutionFinalState extends State<EvolutionFinalScreen>{
  Map<String,dynamic>? data; List tiers=[]; Object? error;
  Future<void> load()async{try{final d=await widget.api.economyMe();final t=await widget.api.evolutionTiers();if(mounted)setState((){data=d;tiers=t;});}catch(e){if(mounted)setState(()=>error=e);}}
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext c)=>_Page(title:'Evolution',body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[
    if(error!=null)Text('Evolution error: '+error.toString(),style:const TextStyle(color:SageTheme.textSecondary)),
    if(data!=null)...[
      Text('Tier: '+(data!['evolution']?['tier']?.toString()??'Bronze'),style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),
      Text('Stage: '+(data!['evolution']?['stage']?.toString()??'LOW')),
      Text('Achievement: '+(data!['evolution']?['lifetime_achievement']?.toString()??'0')),
      const SizedBox(height:12),
      LinearProgressIndicator(value:((data!['evolution']?['progress']?['ratio']??0) as num).toDouble()),
      const SizedBox(height:24),const Text('Canonical tiers',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
      ...tiers.map((e)=>ListTile(title:Text(e['tier']?.toString()??''),trailing:Text(e['threshold']?.toString()??'0'))),
    ] else if(error==null)const Center(child:CircularProgressIndicator()),
  ])));
}

class ProfileFinalScreen extends StatefulWidget {
  const ProfileFinalScreen({required this.api,super.key}); final SageApi api;
  @override State<ProfileFinalScreen> createState()=>_ProfileFinalState();
}
class _ProfileFinalState extends State<ProfileFinalScreen>{
  final name=TextEditingController(),intent=TextEditingController(); bool saving=false;
  Future<void> load()async{try{final d=await widget.api.profileMe();final p=d['profile'] is Map?Map<String,dynamic>.from(d['profile']):{};name.text=p['name']?.toString()??'';intent.text=p['help_intent']?.toString()??'';if(mounted)setState((){});}catch(e){_msg('Profile load failed: '+e.toString());}}
  Future<void> save()async{setState(()=>saving=true);try{await widget.api.updateProfile(name:name.text.trim(),helpIntent:intent.text.trim());_msg('Profile saved.');}catch(e){_msg('Profile save failed: '+e.toString());}finally{if(mounted)setState(()=>saving=false);}}
  void _msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
  @override void initState(){super.initState();load();}
  @override void dispose(){name.dispose();intent.dispose();super.dispose();}
  @override Widget build(BuildContext c)=>_Page(title:'Profile',body:ListView(padding:const EdgeInsets.all(20),children:[
    TextField(controller:name,decoration:const InputDecoration(labelText:'Name')),
    const SizedBox(height:12),TextField(controller:intent,maxLines:3,decoration:const InputDecoration(labelText:'SAGE help intent')),
    const SizedBox(height:16),FilledButton(onPressed:saving?null:save,child:Text(saving?'Saving…':'Save profile')),
  ]));
}

class SettingsFinalScreen extends StatefulWidget {
  const SettingsFinalScreen({required this.api,super.key}); final SageApi api;
  @override State<SettingsFinalScreen> createState()=>_SettingsFinalState();
}
class _SettingsFinalState extends State<SettingsFinalScreen>{
  bool notifications=true,compact=false,saving=false; Map<String,dynamic> basic={};
  Future<void> load()async{try{final d=await widget.api.profileMe();final p=Map<String,dynamic>.from(d['profile']);basic=p['basic_info'] is Map?Map<String,dynamic>.from(p['basic_info']):{};final s=basic['settings'] is Map?Map<String,dynamic>.from(basic['settings']):{};if(mounted)setState((){notifications=s['notifications']??true;compact=s['compact_mode']??false;});}catch(_){}} 
  Future<void> save()async{setState(()=>saving=true);try{basic['settings']={'notifications':notifications,'compact_mode':compact};await widget.api.updateProfile(basicInfo:basic);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Settings saved.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Settings save failed: '+e.toString())));}finally{if(mounted)setState(()=>saving=false);}}
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext c)=>_Page(title:'Settings',body:ListView(padding:const EdgeInsets.all(20),children:[
    SwitchListTile(title:const Text('Notifications'),value:notifications,onChanged:(v)=>setState(()=>notifications=v)),
    SwitchListTile(title:const Text('Compact mode'),value:compact,onChanged:(v)=>setState(()=>compact=v)),
    FilledButton(onPressed:saving?null:save,child:Text(saving?'Saving…':'Save settings')),
  ]));
}

class NotificationsFinalScreen extends StatefulWidget {
  const NotificationsFinalScreen({required this.api,super.key}); final SageApi api;
  @override State<NotificationsFinalScreen> createState()=>_NotificationsFinalState();
}
class _NotificationsFinalState extends State<NotificationsFinalScreen>{
  List items=[]; Object? error;
  Future<void> load()async{try{final v=await widget.api.notifications();if(mounted)setState(()=>items=v);}catch(e){if(mounted)setState(()=>error=e);}}
  Future<void> read(String id)async{try{await widget.api.markNotificationRead(id);await load();}catch(e){}}
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext c)=>_Page(title:'Notifications',body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Activity',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),TextButton(onPressed:()async{await widget.api.markAllNotificationsRead();await load();},child:const Text('Mark all read'))]),
    if(error!=null)Text('Notification error: '+error.toString()),
    ...items.map((n)=>Card(child:ListTile(title:Text(n['title']?.toString()??n['message']?.toString()??'SAGE update'),subtitle:Text(n['created_at']?.toString()??''),trailing:IconButton(icon:const Icon(Icons.done),onPressed:()=>read(n['id'].toString()))))),
    if(items.isEmpty&&error==null)const Padding(padding:EdgeInsets.all(40),child:Text('You are all caught up.')),
  ])));
}

class PaymentFinalScreen extends StatefulWidget {
  const PaymentFinalScreen({required this.api,super.key}); final SageApi api;
  @override State<PaymentFinalScreen> createState()=>_PaymentFinalState();
}
class _PaymentFinalState extends State<PaymentFinalScreen>{
  Map<String,dynamic>? status; Object? error;
  Future<void> load()async{try{final v=await widget.api.paymentStatus();if(mounted)setState(()=>status=v);}catch(e){if(mounted)setState(()=>error=e);}}
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext c)=>_Page(title:'Payments',body:ListView(padding:const EdgeInsets.all(20),children:[
    const Text('Provider readiness',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
    if(status!=null)Card(child:ListTile(title:Text(status!['configured']==true?'Provider configured':'Not configured'),subtitle:Text(status!['message']?.toString()??''))),
    if(error!=null)Text('Payment status error: '+error.toString()),
    const SizedBox(height:20),const Text('No payment action is exposed until a real provider is configured.',style:TextStyle(color:SageTheme.textSecondary)),
  ]));
}

class FileManagerFinalScreen extends StatefulWidget {
  const FileManagerFinalScreen({required this.api,super.key}); final SageApi api;
  @override State<FileManagerFinalScreen> createState()=>_FileManagerFinalState();
}
class _FileManagerFinalState extends State<FileManagerFinalScreen>{
  List items=[]; Object? error;
  Future<void> load()async{try{final v=await widget.api.tasks();if(mounted)setState(()=>items=v);}catch(e){if(mounted)setState(()=>error=e);}}
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext c)=>_Page(title:'File Manager',body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[
    const Text('Task artifacts',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
    if(error!=null)Text('File manager error: '+error.toString()),
    ...items.map((t){final a=t is Map&&t['artifact'] is Map?t['artifact']:null;return a==null?const SizedBox.shrink():Card(child:ListTile(title:Text(a['name']?.toString()??'Artifact'),subtitle:Text(a['mime_type']?.toString()??''),onTap:(){final u=a['url']??a['uri'];if(u!=null)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(u.toString())));},));}),
    if(items.isEmpty&&error==null)const Padding(padding:EdgeInsets.all(40),child:Text('No task artifacts found yet.')),
  ])));
}

class AiStudioFinalScreen extends StatefulWidget {
  const AiStudioFinalScreen({required this.api,super.key}); final SageApi api;
  @override State<AiStudioFinalScreen> createState()=>_AiStudioFinalState();
}
class _AiStudioFinalState extends State<AiStudioFinalScreen>{
  List items=[]; Object? error;
  Future<void> load()async{try{final v=await widget.api.workflowWorkspaces();if(mounted)setState(()=>items=v);}catch(e){if(mounted)setState(()=>error=e);}}
  Future<void> createWorkspace()async{
    final n=TextEditingController(),s=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Create workspace'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Name')),TextField(controller:s,decoration:const InputDecoration(labelText:'Slug'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Create'))]));
    if(ok==true){try{await widget.api.createWorkflowWorkspace(name:n.text.trim(),slug:s.text.trim());await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Create failed: '+e.toString())));}}
    n.dispose();s.dispose();
  }
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext c)=>_Page(title:'AI Studio',body:ListView(padding:const EdgeInsets.all(20),children:[
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Workflow Studio',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),FilledButton.icon(onPressed:createWorkspace,icon:const Icon(Icons.add),label:const Text('Workspace'))]),
    if(error!=null)Text('AI Studio error: '+error.toString()),
    ...items.map((w)=>Card(child:ListTile(title:Text(w['name']?.toString()??w['slug']?.toString()??'Workspace'),subtitle:Text(w['workspace_type']?.toString()??'personal')))),
    if(items.isEmpty&&error==null)const Padding(padding:EdgeInsets.all(40),child:Text('No workspaces yet.')),
  ]));
}
