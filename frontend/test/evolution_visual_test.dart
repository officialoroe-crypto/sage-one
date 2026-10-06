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
}
