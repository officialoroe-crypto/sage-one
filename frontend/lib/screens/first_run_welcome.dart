import 'package:flutter/material.dart';

import '../theme/sage_theme.dart';

class FirstRunWelcomeScreen extends StatefulWidget {
  const FirstRunWelcomeScreen({super.key, this.onComplete});
  final ValueChanged<Set<String>>? onComplete;
  @override State<FirstRunWelcomeScreen> createState() => _FirstRunWelcomeScreenState();
}

class _FirstRunWelcomeScreenState extends State<FirstRunWelcomeScreen> {
  final _capabilities = <String>{'Voice commands','Research','Jobs & earning','Learning','Marketplace'};
  final _selected = <String>{};
  int _step = 0;

  void _continue() {
    if (_step < 2) { setState(() => _step += 1); return; }
    widget.onComplete?.call(Set.unmodifiable(_selected));
    if (mounted) Navigator.of(context).maybePop();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SageTheme.voidBlack,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24,18,24,10),
          child: Row(children: [
            const Text('SAGE ONE', style: TextStyle(letterSpacing: 2.4,fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('0${_step + 1} / 03', style: const TextStyle(color: SageTheme.textSecondary,fontSize: 10,letterSpacing: 1.4)),
          ]),
        ),
        LinearProgressIndicator(value: (_step + 1) / 3,minHeight: 2,backgroundColor: SageTheme.surfaceRaised,valueColor: const AlwaysStoppedAnimation(SageTheme.cyan)),
        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _step == 0 ? _welcome() : _step == 1 ? _capabilityStep() : _readyStep(),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(24,8,24,24),
          child: SizedBox(width: double.infinity,child: FilledButton(onPressed: _continue,child: Text(_step == 2 ? 'ENTER SAGE ONE' : 'CONTINUE'))),
        ),
      ])),
    );
  }

  Widget _welcome() => Padding(
    key: const ValueKey('welcome'), padding: const EdgeInsets.all(28),
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [
      _core(),const SizedBox(height: 34),
      const Text('WELCOME TO SAGE ONE',textAlign: TextAlign.center,style: TextStyle(fontSize:25,fontWeight:FontWeight.w800,letterSpacing:1.1)),
      const SizedBox(height:12),
      const Text('Your AI. Your edge.\nTell SAGE what you need and build from there.',textAlign:TextAlign.center,style:TextStyle(color:SageTheme.textSecondary,height:1.55)),
    ])),
  );

  Widget _capabilityStep() => ListView(
    key: const ValueKey('capabilities'),padding: const EdgeInsets.fromLTRB(24,36,24,12),
    children: [
      const Text('WHAT SHOULD SAGE HELP WITH?',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
      const SizedBox(height:9),
      const Text('Choose anything you want to start with. You can change this later.',style:TextStyle(color:SageTheme.textSecondary,height:1.45)),
      const SizedBox(height:22),
      ..._capabilities.map((item) {
        final selected = _selected.contains(item);
        return Padding(
          padding: const EdgeInsets.only(bottom:10),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => selected ? _selected.remove(item) : _selected.add(item)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds:160),padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(color:selected ? SageTheme.cyan.withValues(alpha:.10) : SageTheme.surface,borderRadius:BorderRadius.circular(18),border:Border.all(color:selected ? SageTheme.cyan : const Color(0x2617D8FF))),
              child: Row(children:[
                Icon(selected ? Icons.check_circle : Icons.circle_outlined,color:selected ? SageTheme.cyan : SageTheme.textSecondary),
                const SizedBox(width:13),Text(item,style:const TextStyle(fontWeight:FontWeight.w600)),
              ]),
            ),
          ),
        );
      }),
    ],
  );

  Widget _readyStep() => Padding(
    key: const ValueKey('ready'),padding:const EdgeInsets.all(28),
    child: Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      _core(),const SizedBox(height:30),
      const Text('YOU ARE READY',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800,letterSpacing:1.2)),
      const SizedBox(height:12),
      Text(_selected.isEmpty ? 'SAGE is ready for your first command.' : 'SAGE is configured around ${_selected.length} starting capabilities.',textAlign:TextAlign.center,style:const TextStyle(color:SageTheme.textSecondary,height:1.5)),
      const SizedBox(height:18),
      const Text('You stay in control of permissions, identity and connected services.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:SageTheme.textSecondary)),
    ])),
  );

  Widget _core() => Container(
    width:118,height:118,
    decoration:BoxDecoration(shape:BoxShape.circle,gradient:const RadialGradient(colors:[SageTheme.surfaceRaised,SageTheme.surface,SageTheme.voidBlack]),boxShadow:[BoxShadow(color:SageTheme.cyan.withValues(alpha:.24),blurRadius:34,spreadRadius:8)],border:Border.all(color:SageTheme.cyan.withValues(alpha:.34))),
    alignment:Alignment.center,
    child:const Text('S',style:TextStyle(fontSize:54,fontWeight:FontWeight.w800,color:SageTheme.textPrimary)),
  );
}
