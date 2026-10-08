import 'package:flutter/material.dart';
import '../theme/sage_theme.dart';
import '../core/sage_api.dart';

class FeatureWorkspace extends StatefulWidget {
  const FeatureWorkspace({required this.title, required this.subtitle, required this.icon, required this.actions, super.key});
  final String title, subtitle; final IconData icon; final List<String> actions;
  @override State<FeatureWorkspace> createState() => _FeatureWorkspaceState();
}
class _FeatureWorkspaceState extends State<FeatureWorkspace> {
  String? _message;
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: SageTheme.voidBlack,
    appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.transparent),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0C2344), Color(0xFF07101E)]),
        borderRadius: BorderRadius.circular(24), border: Border.all(color: SageTheme.cyan.withValues(alpha: .18))),
        child: Row(children: [
          Container(width: 54,height:54,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,color:SageTheme.cyan.withValues(alpha:.1)),child:Icon(widget.icon,color:SageTheme.cyan)),
          const SizedBox(width:16), Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(widget.title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:SageTheme.textPrimary)),const SizedBox(height:5),Text(widget.subtitle,style:const TextStyle(color:SageTheme.textSecondary,fontSize:12,height:1.4))
          ]))
        ])),
      const SizedBox(height:20),
      ...widget.actions.map((a)=>Padding(padding:const EdgeInsets.only(bottom:10),child:FilledButton.tonalIcon(
        onPressed:()=>setState(()=>_message='$a is ready in SAGE ONE.'),
        icon:const Icon(Icons.arrow_forward),label:Align(alignment:Alignment.centerLeft,child:Text(a))))),
      if(_message!=null) ...[const SizedBox(height:18),Text(_message!,style:const TextStyle(color:SageTheme.success,fontWeight:FontWeight.w700))]
    ]));
}

class VoiceListeningScreen extends StatefulWidget {
  const VoiceListeningScreen({super.key});
  @override State<VoiceListeningScreen> createState() => _VoiceListeningScreenState();
}
class _VoiceListeningScreenState extends State<VoiceListeningScreen> {
  final _controller = TextEditingController();
  final _api = SageApi();
  bool _busy = false;
  String? _result;
  @override void dispose(){ _controller.dispose(); _api.dispose(); super.dispose(); }
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    setState(()=>_busy=true);
    try {
      final data = await _api.chat(text);
      final response = data['response'];
      setState(()=>_result = response is Map ? (response['response'] ?? response['content'] ?? response).toString() : response.toString());
    } catch(e) { setState(()=>_result='Command failed: $e'); }
    finally { if(mounted) setState(()=>_busy=false); }
  }
  @override Widget build(BuildContext c)=>Scaffold(
    backgroundColor:SageTheme.voidBlack,
    appBar:AppBar(title:const Text('Voice Command'),backgroundColor:Colors.transparent),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      const Text('VOICE CONTROL',style:TextStyle(color:SageTheme.cyan,fontSize:11,letterSpacing:2,fontWeight:FontWeight.w800)),
      const SizedBox(height:8),
      const Text('Give SAGE a command',style:TextStyle(color:SageTheme.textPrimary,fontSize:28,fontWeight:FontWeight.w800)),
      const SizedBox(height:8),
      const Text('This command surface uses the real SAGE chat pipeline. Microphone capture can feed the same command field without creating a second backend.',style:TextStyle(color:SageTheme.textSecondary,height:1.4)),
      const SizedBox(height:24),
      TextField(controller:_controller,maxLines:4,decoration:const InputDecoration(hintText:'Enter a voice-transcribed command…',border:OutlineInputBorder())),
      const SizedBox(height:12),
      FilledButton.icon(onPressed:_busy?null:_send,icon:const Icon(Icons.mic),label:Text(_busy?'Sending…':'Send command')),
      if(_result!=null) ...[const SizedBox(height:20),Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(borderRadius:BorderRadius.all(Radius.circular(18)),border:Border.fromBorderSide(BorderSide(color:SageTheme.cyan))),child:Text(_result!,style:const TextStyle(color:SageTheme.textPrimary,height:1.45)))]
    ]));
}
class VoiceResponseScreen extends StatelessWidget { const VoiceResponseScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Voice Response',subtitle:'Spoken SAGE answers with playback controls.',icon:Icons.volume_up,actions:['Play latest response','Pause response','Choose voice']);}
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override State<ChatScreen> createState()=>_ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final _api=SageApi();
  final _input=TextEditingController();
  final _scroll=ScrollController();
  final List<Map<String,String>> _messages=[];
  String? _sessionId;
  bool _busy=false;
  @override void dispose(){_input.dispose();_scroll.dispose();_api.dispose();super.dispose();}
  Future<void> _send() async {
    final message=_input.text.trim();
    if(message.isEmpty||_busy)return;
    _input.clear();
    setState((){_messages.add({'role':'user','text':message});_busy=true;});
    try {
      final data=await _api.chat(message,sessionId:_sessionId);
      _sessionId=data['session_id']?.toString()??_sessionId;
      final value=data['response'];
      final text=value is Map ? (value['response']??value['content']??value).toString() : value.toString();
      if(mounted)setState(()=>_messages.add({'role':'sage','text':text}));
    } catch(e){if(mounted)setState(()=>_messages.add({'role':'error','text':'SAGE could not complete the request: $e'}));}
    finally{if(mounted)setState(()=>_busy=false);}
    if(mounted)WidgetsBinding.instance.addPostFrameCallback((_)=>_scrollToEnd());
  }
  void _scrollToEnd(){if(_scroll.hasClients)_scroll.animateTo(_scroll.position.maxScrollExtent,duration:const Duration(milliseconds:250),curve:Curves.easeOut);}
  @override Widget build(BuildContext c)=>Scaffold(
    backgroundColor:SageTheme.voidBlack,
    appBar:AppBar(title:const Text('SAGE Chat'),backgroundColor:Colors.transparent,actions:[IconButton(onPressed:_busy?null:()=>setState(()=>_messages.clear()),icon:const Icon(Icons.add_comment_outlined))]),
    body:Column(children:[
      Expanded(child:_messages.isEmpty?const Center(child:Text('Ask SAGE to research, plan, remember, create or execute.',style:TextStyle(color:SageTheme.textSecondary))):ListView.builder(controller:_scroll,padding:const EdgeInsets.all(16),itemCount:_messages.length,itemBuilder:(context,i){final m=_messages[i];final sage=m['role']=='sage';return Align(alignment:sage?Alignment.centerLeft:Alignment.centerRight,child:Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(14),constraints:const BoxConstraints(maxWidth:700),decoration:BoxDecoration(color:sage?SageTheme.surface:SageTheme.cyan.withValues(alpha:.12),borderRadius:BorderRadius.circular(18)),child:Text(m['text']??'',style:TextStyle(color:m['role']=='error'?SageTheme.error:SageTheme.textPrimary,height:1.4))));})),
      SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(12,8,12,12),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:TextField(controller:_input,maxLines:4,minLines:1,decoration:const InputDecoration(hintText:'Message SAGE…',border:OutlineInputBorder()))),const SizedBox(width:8),IconButton.filled(onPressed:_busy?null:_send,icon:Icon(_busy?Icons.hourglass_top:Icons.arrow_upward))]))),
    ]));
}
class AppsScreen extends StatelessWidget { const AppsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Apps',subtitle:'Connected tools and future integrations in one control surface.',icon:Icons.apps,actions:['Browse connected apps','Connect an app','Manage permissions']);}
class EarningsScreen extends StatelessWidget { const EarningsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Earnings',subtitle:'Track completed work, payouts and creator income.',icon:Icons.trending_up,actions:['View earnings','View pending payouts','Open earnings history']);}
class MarketplaceScreen extends StatelessWidget { const MarketplaceScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Marketplace',subtitle:'Discover services, tools and SAGE-powered work.',icon:Icons.storefront,actions:['Browse marketplace','View saved items','Open seller tools']);}
class JobsScreen extends StatelessWidget { const JobsScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Jobs',subtitle:'Work opportunities and execution-ready job workflows.',icon:Icons.work_outline,actions:['Find jobs','Track applications','Open active work']);}
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
