import 'package:flutter/material.dart';

import 'core/sage_api.dart';
import 'screens/command_center.dart';
import 'theme/sage_theme.dart';

void main() => runApp(const SageOneApp());

class SageOneApp extends StatelessWidget {
  const SageOneApp({SageApi? api, super.key}) : _api = api;

  final SageApi? _api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAGE ONE',
      debugShowCheckedModeBanner: false,
      theme: SageTheme.dark(),
      home: CommandCenter(api: _api ?? SageApi()),
    );
  }
}
