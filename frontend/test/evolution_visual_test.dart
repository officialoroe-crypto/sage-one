import 'package:flutter_test/flutter_test.dart';
import 'package:sage_one/evolution/evolution_transition.dart';
import 'package:sage_one/evolution/evolution_visual.dart';

void main() {
  test('locked Evolution catalog contains all 13 stages', () {
    expect(evolutionVisuals.length, 13);
    expect(evolutionVisualFor('Bronze').order, 1);
    expect(evolutionVisualFor('Diamond Sovereign').order, 9);
    expect(evolutionVisualFor('Californium Overlord').order, 13);
  });

  test('intensity changes visual energy without changing rank identity', () {
    final low = evolutionVisualFor('Gold', intensity: EvolutionIntensity.low);
    final high = evolutionVisualFor('Gold', intensity: EvolutionIntensity.high);

    expect(low.name, 'Gold');
    expect(high.name, 'Gold');
    expect(low.accent, high.accent);
    expect(low.particleDensity, lessThan(high.particleDensity));
    expect(low.glowOpacity, lessThan(high.glowOpacity));
  });

  test('unknown stages fail safely to SAGE core identity', () {
    final visual = evolutionVisualFor('Unknown Stage');
    expect(visual.order, 0);
    expect(visual.name, 'SAGE');
  });
  testWidgets('Evolution atmosphere renders one deterministic visual layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EvolutionAtmosphere(
            visual: evolutionVisualFor(
              'Gold',
              intensity: EvolutionIntensity.mid,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(find.byType(EvolutionAtmosphere), findsOneWidget);
    expect(find.byType(CustomPaint), findsOneWidget);
    expect(
      tester.widget<CustomPaint>(find.byType(CustomPaint)).painter,
      isNotNull,
    );
  });

  testWidgets('Evolution transition mounts and completes as a visual overlay', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const SizedBox.expand(),
              EvolutionTransition(
                from: evolutionVisualFor(
                  'Bronze',
                  intensity: EvolutionIntensity.high,
                ),
                to: evolutionVisualFor(
                  'Silver',
                  intensity: EvolutionIntensity.low,
                ),
                duration: const Duration(milliseconds: 100),
                onCompleted: () => completed = true,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(IgnorePointer), findsOneWidget);
    expect(find.byType(CustomPaint), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    expect(completed, isTrue);
  });

}
