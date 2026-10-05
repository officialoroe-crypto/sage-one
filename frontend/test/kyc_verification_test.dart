import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/screens/kyc_verification.dart';

void main() {
  testWidgets('walks through KYC preparation without claiming verification', (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(MaterialApp(home: KycVerificationScreen(onComplete: (value) => result = value)));
    expect(find.text('IDENTITY VERIFICATION'), findsOneWidget);
    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('STEP 3 OF 3'), findsOneWidget);
    expect(find.text('Continue to verification'), findsOneWidget);
    await tester.tap(find.text('Continue to verification'));
    await tester.pump();
    expect(result?['status'], 'ready_for_verification');
    expect(find.textContaining('does not treat this screen as proof of identity'), findsOneWidget);
  });
}
