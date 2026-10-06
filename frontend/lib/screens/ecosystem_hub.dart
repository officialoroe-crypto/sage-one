import 'package:flutter/material.dart';
import '../theme/sage_theme.dart';

class EcosystemScaffold extends StatelessWidget {
  const EcosystemScaffold({required this.title, required this.eyebrow, required this.subtitle, required this.icon, required this.child, this.accent = SageTheme.cyan, super.key});
  final String title, eyebrow, subtitle; final IconData icon; final Widget child; final Color accent;
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: SageTheme.voidBlack,
    appBar: AppBar(backgroundColor: Colors.transparent, titleSpacing: 18, title: Row(children: [
      Container(width: 38,height:38,decoration:BoxDecoration(shape:BoxShape.circle,color:accent.withValues(alpha:.09),border:Border.all(color:accent.withValues(alpha:.32)),boxShadow:[BoxShadow(color:accent.withValues(alpha:.12),blurRadius:18)]),child:Icon(icon,color:accent,size:19)),
      const SizedBox(width:11), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(eyebrow,style:TextStyle(fontSize:8,letterSpacing:1.8,color:accent,fontWeight:FontWeight.w800)),
        Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w700)),
      ])),
    ])),
    body: SafeArea(child: SingleChildScrollView(padding:const EdgeInsets.fromLTRB(18,8,18,30),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(subtitle,style:const TextStyle(color:SageTheme.textSecondary,height:1.45)),const SizedBox(height:18),child,
    ])),
  );
}

class AppsHubScreen extends StatelessWidget {
  const AppsHubScreen({super.key});
  static const _apps = [
    ('Marketplace','Buy and sell with SAGE.',Icons.storefront,SageTheme.cyan),
    ('Jobs','Find work matched to your skills.',Icons.work_outline,SageTheme.blue),
    ('Learning','Build skills with an AI mentor.',Icons.school_outlined,SageTheme.violet),
    ('Community','Connect, share and collaborate.',Icons.groups_outlined,SageTheme.cyan),
    ('Earnings','Track work and income.',Icons.trending_up,SageTheme.gold),
    ('File Manager','Keep artifacts and exports organized.',Icons.folder_copy_outlined,SageTheme.blue),
    ('AI Studio','Build reusable AI workflows.',Icons.auto_awesome,SageTheme.violet),
  ];
  @override Widget build(BuildContext context) => EcosystemScaffold(
    title:'Apps Hub',eyebrow:'SAGE ECOSYSTEM',
    subtitle:'One place for the experiences that extend SAGE ONE. Your core command surface stays focused; everything else lives here.',
    icon:Icons.apps,
    child:GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:_apps.length,
      gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.15),
      itemBuilder:(context,i){final app=_apps[i];return _AppCard(title:app.$1,subtitle:app.$2,icon:app.$3,accent:app.$4,onTap:(){
        final Widget? screen=switch(app.$1){
          'Marketplace'=>const EcosystemMarketplaceScreen(),'Jobs'=>const EcosystemJobsScreen(),'Learning'=>const EcosystemLearningScreen(),'Community'=>const EcosystemCommunityScreen(),'Earnings'=>const EcosystemEarningsScreen(),_=>null};
        if(screen!=null){Navigator.push(context,MaterialPageRoute(builder:(_)=>screen));}
        else{ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(app.$1+' workspace is being connected next.')));}
      });}),
  );
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.title,required this.subtitle,required this.icon,required this.accent,required this.onTap});
  final String title,subtitle; final IconData icon; final Color accent; final VoidCallback onTap;
  @override Widget build(BuildContext context)=>Material(color:SageTheme.surface,borderRadius:BorderRadius.circular(20),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(20),child:Container(
    padding:const EdgeInsets.all(15),
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),border:Border.all(color:accent.withValues(alpha:.17)),gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[accent.withValues(alpha:.075),SageTheme.surfaceRaised.withValues(alpha:.82)])),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:accent,size:24),const Spacer(),Text(title,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w700)),const SizedBox(height:4),Text(subtitle,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10.5,color:SageTheme.textSecondary,height:1.3))]),
  )));
}

class EcosystemMarketplaceScreen extends StatelessWidget { const MarketplaceScreen({super.key}); @override Widget build(BuildContext context)=>EcosystemScaffold(title:'Marketplace',eyebrow:'SAGE MARKET',subtitle:'A Nepal-first buying and selling surface. Listings stay simple; SAGE can help compare, negotiate and organize the next step.',icon:Icons.storefront,child:const Column(children:[
  _MetricRow(label:'Discover',value:'Products • Services • Courses'),
  _ActionTile(icon:Icons.search,title:'Browse listings',subtitle:'Search categories and nearby opportunities.'),
  _ActionTile(icon:Icons.add_circle_outline,title:'Create a listing',subtitle:'Prepare photos, description and price with SAGE.'),
  _ActionTile(icon:Icons.bookmark_border,title:'Saved items',subtitle:'Keep listings you want to revisit.'),
  _ActionTile(icon:Icons.shield_outlined,title:'SAGE payment protection',subtitle:'Payment rails and settlement stay in the controlled SAGE flow.'),
]));}

class EcosystemJobsScreen extends StatelessWidget { const JobsScreen({super.key}); @override Widget build(BuildContext context)=>EcosystemScaffold(title:'Jobs',eyebrow:'SAGE WORK',subtitle:'Turn your profile, skills and goals into practical work opportunities. Start with Nepal-first matching.',icon:Icons.work_outline,accent:SageTheme.blue,child:const Column(children:[
  _MetricRow(label:'Match mode',value:'Skills • Location • Availability',accent:SageTheme.blue),
  _ActionTile(icon:Icons.manage_search,title:'Find a job',subtitle:'Tell SAGE what kind of work you want.'),
  _ActionTile(icon:Icons.description_outlined,title:'Build your CV',subtitle:'Use your profile and verified skills as the starting point.'),
  _ActionTile(icon:Icons.send_outlined,title:'Applications',subtitle:'Track submitted and active applications.'),
  _ActionTile(icon:Icons.business_center_outlined,title:'Employer tools',subtitle:'Post roles and manage candidate connections.'),
]));}

class EcosystemLearningScreen extends StatelessWidget { const LearningScreen({super.key}); @override Widget build(BuildContext context)=>EcosystemScaffold(title:'Learning',eyebrow:'SAGE ACADEMY',subtitle:'A practical learning surface built around goals, progress and an AI mentor—not a static course list.',icon:Icons.school_outlined,accent:SageTheme.violet,child:const Column(children:[
  _MetricRow(label:'Path',value:'Goal → Lessons → Practice → Proof',accent:SageTheme.violet),
  _ActionTile(icon:Icons.play_circle_outline,title:'Continue learning',subtitle:'Resume the next lesson in your active path.'),
  _ActionTile(icon:Icons.explore_outlined,title:'Explore paths',subtitle:'Choose skills connected to work and earning goals.'),
  _ActionTile(icon:Icons.auto_graph,title:'My progress',subtitle:'See completed learning and skill growth.'),
  _ActionTile(icon:Icons.psychology_alt_outlined,title:'Ask SAGE',subtitle:'Turn a question into a guided learning session.'),
]));}

class EcosystemCommunityScreen extends StatelessWidget { const CommunityScreen({super.key}); @override Widget build(BuildContext context)=>EcosystemScaffold(title:'Community',eyebrow:'SAGE COMMUNITY',subtitle:'A future-ready collaboration space with private-first controls and useful activity—not noisy social feeds.',icon:Icons.groups_outlined,child:const Column(children:[
  _MetricRow(label:'Mode',value:'Learn • Share • Collaborate'),
  _ActionTile(icon:Icons.forum_outlined,title:'Community spaces',subtitle:'Discover focused groups and discussions.'),
  _ActionTile(icon:Icons.edit_outlined,title:'Create a post',subtitle:'Share a question, result, opportunity or resource.'),
  _ActionTile(icon:Icons.people_outline,title:'My activity',subtitle:'Review replies and collaboration activity.'),
  _ActionTile(icon:Icons.lock_outline,title:'Privacy controls',subtitle:'Choose what you share and with whom.'),
]));}

class EcosystemEarningsScreen extends StatelessWidget { const EarningsScreen({super.key}); @override Widget build(BuildContext context)=>EcosystemScaffold(title:'Earnings',eyebrow:'SAGE EARN',subtitle:'A clear view of completed work, pending payouts and income history. Spark balance remains separate from Evolution progress.',icon:Icons.trending_up,accent:SageTheme.gold,child:const Column(children:[
  _MetricRow(label:'Today',value:'NPR 0.00',accent:SageTheme.gold),
  _ActionTile(icon:Icons.task_alt,title:'Completed work',subtitle:'Review work that has generated earnings.'),
  _ActionTile(icon:Icons.pending_actions,title:'Pending payouts',subtitle:'See earnings waiting for settlement.'),
  _ActionTile(icon:Icons.receipt_long_outlined,title:'Earnings history',subtitle:'Track completed earning events and fees.'),
  _ActionTile(icon:Icons.account_balance_wallet_outlined,title:'Open Spark Wallet',subtitle:'Move to the economic balance without changing Evolution.'),
]));}

class _MetricRow extends StatelessWidget { const _MetricRow({required this.label,required this.value,this.accent=SageTheme.cyan}); final String label,value; final Color accent;
  @override Widget build(BuildContext context)=>Container(width:double.infinity,padding:const EdgeInsets.all(16),margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:accent.withValues(alpha:.055),borderRadius:BorderRadius.circular(18),border:Border.all(color:accent.withValues(alpha:.14))),child:Row(children:[Text(label.toUpperCase(),style:TextStyle(fontSize:9,letterSpacing:1.5,color:accent,fontWeight:FontWeight.w800)),const Spacer(),Flexible(child:Text(value,textAlign:TextAlign.right,style:const TextStyle(fontSize:12,color:SageTheme.textSecondary)))]));}

class _ActionTile extends StatelessWidget { const _ActionTile({required this.icon,required this.title,required this.subtitle}); final IconData icon; final String title,subtitle;
  @override Widget build(BuildContext context)=>Container(width:double.infinity,margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:SageTheme.surface,borderRadius:BorderRadius.circular(18),border:Border.all(color:SageTheme.cyan.withValues(alpha:.10))),child:Row(children:[Icon(icon,color:SageTheme.cyan,size:21),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:3),Text(subtitle,style:const TextStyle(fontSize:11,color:SageTheme.textSecondary,height:1.35))])),const Icon(Icons.chevron_right,size:19,color:SageTheme.textSecondary)]));}
