import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sage_one/evolution/evolution_visual.dart';

const _captureSize = Size(320, 480);

Future<Uint8List> _capturePixels(
  WidgetTester tester,
  EvolutionVisual visual,
) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox.fromSize(
            size: _captureSize,
            child: RepaintBoundary(
              key: key,
              child: EvolutionAtmosphere(
                visual: visual,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  expect(boundary.size, _captureSize);
  final image = await boundary.toImage(pixelRatio: 1);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) {
      throw StateError('Flutter did not return raster pixels for Evolution.');
    }
    return Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  } finally {
    image.dispose();
  }
}

int _pixelFingerprint(Uint8List pixels) {
  var hash = 0x811c9dc5;
  for (final byte in pixels) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

List<int> _pixelAt(Uint8List pixels, int x, int y) {
  final offset = (y * _captureSize.width.toInt() + x) * 4;
  return pixels.sublist(offset, offset + 4);
}

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

  testWidgets('Evolution atmosphere has deterministic raster pixels', (
    tester,
  ) async {
    final visual = evolutionVisualFor(
      'Gold',
      intensity: EvolutionIntensity.mid,
    );
    final first = await _capturePixels(tester, visual);
    final second = await _capturePixels(tester, visual);

    expect(second, equals(first));
    expect(
      _pixelAt(first, 319, 479),
      equals([0, 0, 0, 255]),
      reason: 'the permanent dark SAGE base must remain visible at the edge',
    );
  });

  testWidgets('all 13 Evolution stages produce distinct raster signatures', (
    tester,
  ) async {
    final fingerprints = <int>{};
    for (final visual in evolutionVisuals.values) {
      final pixels = await _capturePixels(tester, visual);
      fingerprints.add(_pixelFingerprint(pixels));
    }

    expect(fingerprints, hasLength(13));
  });

  testWidgets('Low Mid and High render differently without changing rank', (
    tester,
  ) async {
    final lowVisual = evolutionVisualFor(
      'Gold',
      intensity: EvolutionIntensity.low,
    );
    final midVisual = evolutionVisualFor(
      'Gold',
      intensity: EvolutionIntensity.mid,
    );
    final highVisual = evolutionVisualFor(
      'Gold',
      intensity: EvolutionIntensity.high,
    );

    final low = await _capturePixels(tester, lowVisual);
    final mid = await _capturePixels(tester, midVisual);
    final high = await _capturePixels(tester, highVisual);

    expect({lowVisual.name, midVisual.name, highVisual.name}, {'Gold'});
    expect({lowVisual.accent, midVisual.accent, highVisual.accent}, {
      lowVisual.accent,
    });
    expect(
      {
        _pixelFingerprint(low),
        _pixelFingerprint(mid),
        _pixelFingerprint(high),
      },
      hasLength(3),
    );
  });
}
