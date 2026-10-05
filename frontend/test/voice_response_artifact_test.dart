import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_one/screens/voice_response.dart';
import 'package:sage_one/screens/task_artifact.dart';

void main() {
  testWidgets('voice response toggles playback', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VoiceResponseScreen()));
    expect(find.text('SAGE HAS RESPONDED'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pump();
    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
  });

  testWidgets('completed artifact opens full content', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: TaskArtifactScreen(title: 'Test artifact', content: 'Result content'),
    ));
    expect(find.text('Your task is complete.'), findsOneWidget);
    await tester.tap(find.text('OPEN ARTIFACT'));
    await tester.pumpAndSettle();
    expect(find.text('Result content'), findsOneWidget);
  });
}
