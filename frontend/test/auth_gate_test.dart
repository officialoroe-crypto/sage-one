import 'package:flutter_test/flutter_test.dart';

import 'package:sage_one/screens/auth_gate.dart';

void main() {
  group('AuthGate onboarding routing', () {
    test('owner developer session bypasses onboarding even for a new profile', () {
      expect(
        shouldRequireOnboarding(
          {'onboarding_completed': false, 'phone_verified': false},
          developerMode: true,
          ownerMode: true,
        ),
        isFalse,
      );
    });

    test('owner session bypasses onboarding even without developer mode', () {
      expect(
        shouldRequireOnboarding(
          {'onboarding_completed': false, 'phone_verified': false},
          developerMode: false,
          ownerMode: true,
        ),
        isFalse,
      );
    });

    test('normal authenticated user still requires onboarding when incomplete', () {
      expect(
        shouldRequireOnboarding(
          {'onboarding_completed': false, 'phone_verified': false},
          developerMode: false,
          ownerMode: false,
        ),
        isTrue,
      );
    });

    test('normal authenticated user skips onboarding when complete', () {
      expect(
        shouldRequireOnboarding(
          {'onboarding_completed': true, 'phone_verified': true},
          developerMode: false,
          ownerMode: false,
        ),
        isFalse,
      );
    });
  });
}
