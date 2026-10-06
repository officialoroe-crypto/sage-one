import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_one/screens/ecosystem_hub.dart';

void main() {
  testWidgets('Apps Hub exposes the core SAGE ecosystem', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppsHubScreen()));
    expect(find.text('Apps Hub'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
  });

  testWidgets('Jobs surface exposes matching and CV actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EcosystemJobsScreen()));
    expect(find.text('Find a job'), findsOneWidget);
    expect(find.text('Build your CV'), findsOneWidget);
    expect(find.text('Applications'), findsOneWidget);
  });

  testWidgets('Marketplace surface keeps payment protection visible', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EcosystemMarketplaceScreen()));
    expect(find.text('Browse listings'), findsOneWidget);
    expect(find.text('Create a listing'), findsOneWidget);
    expect(find.text('SAGE payment protection'), findsOneWidget);
  });

  testWidgets('Earnings states Spark and Evolution separation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EcosystemEarningsScreen()));
    expect(find.textContaining('Spark balance remains separate from Evolution progress.'), findsOneWidget);
    expect(find.text('Completed work'), findsOneWidget);
    expect(find.text('Pending payouts'), findsOneWidget);
  });
}
