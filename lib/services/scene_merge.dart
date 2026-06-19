import 'dart:async';

import 'package:iris/services/gemini_service.dart';

/// Which information layers contributed to a [SceneReport]. Tracked so the
/// UI can tell the user (and a mentor can see) whether the spoken answer was
/// fully AI-grounded or fell back to pre-mapped data.
enum Layer { gps, vision, mapsGrounding, cachedGraph }

/// The output of a "Where am I?" query: a single spoken string for TTS plus
/// any Google Maps citations that must be rendered via [MapsAttribution].
class SceneReport {
  final String spokenText;
  final List<GroundingSource> sources;
  final Set<Layer> layersUsed;
  final bool degraded;
  final String? fallbackNote;

  const SceneReport({
    required this.spokenText,
    required this.sources,
    required this.layersUsed,
    required this.degraded,
    this.fallbackNote,
  });

  bool get hasSources => sources.isNotEmpty;
}

/// Merges the two parallel calls (vision + reverse geocode) into one
/// spoken report with a graceful degradation ladder:
///
///   1. Both succeed      -> vision describes immediate surroundings, reverse
///      geocode adds place context.
///   2. Vision fails      -> fall back to `graphFallback` (pre-mapped hazard
///      cue from the campus graph) or a non-hallucinated safe message.
///   3. Reverse geocode fails -> spoken text still works, just no place label.
///   4. Both fail         -> graph fallback, else the human-override floor:
///      "I can't get a reading right now. Use the human-verified audio cue."
///
/// The two calls run in parallel, each has an independent timeout, and
/// neither failure breaks the other. The class is pure with respect to
/// network — it takes the two calls as injected functions so it can be
/// unit-tested without hitting any API.
class SceneMerger {
  const SceneMerger();

  static const String cameraRaiseCue =
      'For a better reading, raise your phone and point the camera toward a nearby building or sign.';

  Future<SceneReport> compose({
    required Future<String> Function() visionCall,
    Future<String> Function(GroundedAnswer? grounding)? groundedVisionCall,
    required Future<GroundedAnswer> Function() groundingCall,
    String? graphFallback,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final layers = <Layer>{Layer.gps};
    final buffer = StringBuffer();
    final sources = <GroundingSource>[];
    final failures = <String>[];
    bool degraded = false;

    final _GuardedResult<String> visionResult;
    final _GuardedResult<GroundedAnswer> groundingResult;
    final usesGroundedVision = groundedVisionCall != null;

    if (!usesGroundedVision) {
      // Run both calls in parallel. Each is independently guarded by a
      // timeout and a catch so a slow/failing layer never blocks the other.
      final results = await Future.wait([
        _guard(visionCall, timeout, 'vision'),
        _guard(groundingCall, timeout, 'grounding'),
      ]);

      visionResult = results[0] as _GuardedResult<String>;
      groundingResult = results[1] as _GuardedResult<GroundedAnswer>;
    } else {
      // Grounded mode: get the place context first, then let Kimi produce one
      // usable narration from both the camera frame and map result.
      groundingResult = await _guard(groundingCall, timeout, 'grounding');
      visionResult = await _guard(
        () => groundedVisionCall(
          groundingResult.ok ? groundingResult.value : null,
        ),
        timeout,
        'vision',
      );
    }

    // ---- Vision layer ----
    String? spokenVision;
    if (visionResult.ok) {
      spokenVision = visionResult.value!.trim();
      if (spokenVision.isNotEmpty && !_isUnsafeUnclear(spokenVision)) {
        layers.add(Layer.vision);
        buffer.write(spokenVision);
      } else if (spokenVision.isNotEmpty) {
        // Model honestly said it can't see — surface that, don't hide it.
        buffer.write(spokenVision);
        degraded = true;
        failures.add('vision: unclear image');
      }
    } else {
      degraded = true;
      failures.add('vision: ${visionResult.error}');
      if (graphFallback != null && graphFallback.trim().isNotEmpty) {
        layers.add(Layer.cachedGraph);
        buffer.write(graphFallback.trim());
      } else {
        buffer.write(
          "I can't see my surroundings right now. Use the human-verified audio cue.",
        );
      }
    }

    // ---- Grounding layer ----
    if (groundingResult.ok) {
      final answer = groundingResult.value!;
      final t = answer.text.trim();
      if (t.isNotEmpty) {
        layers.add(Layer.mapsGrounding);
        if (!usesGroundedVision) {
          if (buffer.isNotEmpty) buffer.write(' ');
          buffer.write(t);
        }
        sources.addAll(answer.sources);
      }
    } else {
      degraded = true;
      failures.add('grounding: ${groundingResult.error}');
      // Grounding failure is silent in speech — no citations is acceptable.
      // The user still gets a usable scene description from vision/graph.
    }

    if (buffer.isNotEmpty) {
      buffer.write(' ');
      buffer.write(cameraRaiseCue);
    }

    final note = failures.isEmpty
        ? null
        : failures.join('; ').replaceAll(RegExp(r'\s+'), ' ');

    return SceneReport(
      spokenText: buffer.toString().trim(),
      sources: sources,
      layersUsed: layers,
      degraded: degraded,
      fallbackNote: note,
    );
  }

  /// Wraps an async call with a timeout + catch, returning a [_GuardedResult]
  /// so a failing layer is reported rather than thrown.
  Future<_GuardedResult<T>> _guard<T>(
    Future<T> Function() call,
    Duration timeout,
    String label,
  ) async {
    try {
      final value = await call().timeout(timeout);
      return _GuardedResult<T>.ok(value);
    } on TimeoutException {
      return _GuardedResult<T>.fail(
        '$label timed out after ${timeout.inSeconds}s',
      );
    } catch (e) {
      return _GuardedResult<T>.fail('$label: $e');
    }
  }

  /// Treat the model's honest "I can't see clearly" as degraded so the UI
  /// shows the fallback path rather than pretending it succeeded.
  bool _isUnsafeUnclear(String text) {
    final lower = text.toLowerCase();
    return lower.contains("can't see") ||
        lower.contains("cannot see") ||
        lower.contains("image is unclear") ||
        lower.contains("too dark");
  }
}

class _GuardedResult<T> {
  final T? value;
  final String? error;
  final bool ok;
  const _GuardedResult.ok(this.value) : error = null, ok = true;
  const _GuardedResult.fail(this.error) : value = null, ok = false;
}
