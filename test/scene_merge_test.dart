import 'package:flutter_test/flutter_test.dart';
import 'package:iris/services/gemini_service.dart';
import 'package:iris/services/scene_merge.dart';

void main() {
  const merger = SceneMerger();

  GroundedAnswer answer(String text, [List<GroundingSource> sources = const []]) =>
      GroundedAnswer(text: text, sources: sources);

  test('both layers succeed: vision + grounding merged, sources carried', () async {
    final r = await merger.compose(
      visionCall: () async => 'Stairs 3 metres ahead, door to the left is closed.',
      groundingCall: () async => answer(
          'The nearest accessible entrance is the East Door, about 40 metres to your right.',
          [const GroundingSource(title: 'Library East Entrance', uri: 'https://maps.google.com/?cid=1')]),
    );
    expect(r.spokenText, contains('Stairs 3 metres ahead'));
    expect(r.spokenText, contains('East Door'));
    expect(r.layersUsed, containsAll([Layer.vision, Layer.mapsGrounding]));
    expect(r.degraded, isFalse);
    expect(r.sources.single.uri, 'https://maps.google.com/?cid=1');
  });

  test('vision fails -> graph fallback used, grounding still merged', () async {
    final r = await merger.compose(
      visionCall: () async => throw Exception('network down'),
      groundingCall: () async => answer('You are near the Science Building.'),
      graphFallback: 'Pre-mapped cue: covered walkway to the library is 20m ahead.',
    );
    expect(r.spokenText, contains('covered walkway'));
    expect(r.spokenText, contains('Science Building'));
    expect(r.layersUsed, containsAll([Layer.cachedGraph, Layer.mapsGrounding]));
    expect(r.layersUsed, isNot(contains(Layer.vision)));
    expect(r.degraded, isTrue);
    expect(r.fallbackNote, contains('vision'));
  });

  test('both fail and no graph fallback -> human-override floor message', () async {
    final r = await merger.compose(
      visionCall: () async => throw Exception('offline'),
      groundingCall: () async => throw Exception('offline'),
      graphFallback: null,
    );
    expect(r.spokenText, contains('human-verified audio cue'));
    expect(r.layersUsed, isNot(contains(Layer.vision)));
    expect(r.layersUsed, isNot(contains(Layer.mapsGrounding)));
    expect(r.degraded, isTrue);
    expect(r.sources, isEmpty);
  });

  test('both fail with graph fallback -> graph cue used, human floor not triggered',
      () async {
    final r = await merger.compose(
      visionCall: () async => throw Exception('offline'),
      groundingCall: () async => throw Exception('offline'),
      graphFallback: 'Pre-mapped cue: you are at the Central Plaza.',
    );
    expect(r.spokenText, contains('Central Plaza'));
    expect(r.spokenText, isNot(contains('human-verified')));
    expect(r.layersUsed, contains(Layer.cachedGraph));
    expect(r.degraded, isTrue);
  });

  test('vision honestly reports unclear image -> degraded flagged, no fabrication',
      () async {
    final r = await merger.compose(
      visionCall: () async => "I can't see clearly right now.",
      groundingCall: () async => answer('You are near the Library.'),
    );
    expect(r.spokenText, contains("can't see clearly"));
    expect(r.spokenText, contains('Library'));
    expect(r.layersUsed, isNot(contains(Layer.vision)));
    expect(r.degraded, isTrue);
  });

  test('timeout on vision is caught and degraded, grounding still used', () async {
    final r = await merger.compose(
      visionCall: () => Future.delayed(const Duration(seconds: 10), () => 'late'),
      groundingCall: () async => answer('Near the Arts Building.'),
      timeout: const Duration(milliseconds: 50),
      graphFallback: null,
    );
    expect(r.degraded, isTrue);
    expect(r.fallbackNote, contains('timed out'));
    expect(r.layersUsed, contains(Layer.mapsGrounding));
    expect(r.spokenText, contains('Arts Building'));
  });

  test('grounding fails silently in speech but flagged degraded', () async {
    final r = await merger.compose(
      visionCall: () async => 'Path is clear, kerb edge to the right.',
      groundingCall: () async => throw Exception('maps quota exceeded'),
    );
    expect(r.spokenText, 'Path is clear, kerb edge to the right.');
    expect(r.sources, isEmpty);
    expect(r.layersUsed, contains(Layer.vision));
    expect(r.layersUsed, isNot(contains(Layer.mapsGrounding)));
    expect(r.degraded, isTrue);
    expect(r.fallbackNote, contains('grounding'));
  });
}
