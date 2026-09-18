import 'package:flutter/material.dart';

import 'core/sage_api.dart';
import 'screens/command_center.dart';
import 'theme/sage_theme.dart';

void main() => runApp(const SageOneApp());

class SageOneApp extends StatelessWidget {
  const SageOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAGE ONE',
      debugShowCheckedModeBanner: false,
      theme: SageTheme.dark(),
      home: CommandCenter(api: SageApi()),
    );
  }
}
