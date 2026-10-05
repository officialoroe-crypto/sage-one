import 'package:flutter/material.dart';
import '../theme/sage_theme.dart';

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
            Text(widget.title,style:SageTheme.headingStyle),const SizedBox(height:5),Text(widget.subtitle,style:const TextStyle(color:SageTheme.textSecondary,fontSize:12,height:1.4))
          ]))
        ])),
      const SizedBox(height:20),
      ...widget.actions.map((a)=>Padding(padding:const EdgeInsets.only(bottom:10),child:FilledButton.tonalIcon(
        onPressed:()=>setState(()=>_message='$a is ready in SAGE ONE.'),
        icon:const Icon(Icons.arrow_forward),label:Align(alignment:Alignment.centerLeft,child:Text(a))))),
      if(_message!=null) ...[const SizedBox(height:18),Text(_message!,style:const TextStyle(color:SageTheme.success,fontWeight:FontWeight.w700))]
    ]));
}

class VoiceListeningScreen extends StatelessWidget { const VoiceListeningScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Voice Listening',subtitle:'Hands-free command capture with explicit user control.',icon:Icons.mic,actions:['Start listening','Stop listening','Set auto-send']);}
class VoiceResponseScreen extends StatelessWidget { const VoiceResponseScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Voice Response',subtitle:'Spoken SAGE answers with playback controls.',icon:Icons.volume_up,actions:['Play latest response','Pause response','Choose voice']);}
class ChatScreen extends StatelessWidget { const ChatScreen({super.key}); @override Widget build(BuildContext c)=>const FeatureWorkspace(title:'Chat',subtitle:'Persistent conversational workspace connected to SAGE tasks.',icon:Icons.chat_bubble_outline,actions:['New conversation','Continue last conversation','Attach context']);}
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
