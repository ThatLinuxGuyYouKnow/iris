import 'dart:js_interop';

import 'package:iris/services/obstacle_detection_service.dart';
import 'package:web/web.dart' as web;

/// Haptics feedback using the browser's Vibration API.
///
/// This works in most mobile browsers and PWAs, including iOS Safari when
/// the page has been added to the home screen.
class HapticsService {
  static final HapticsService _instance = HapticsService._internal();
  factory HapticsService() => _instance;
  HapticsService._internal();

  bool? _canVibrateCache;

  bool get _canVibrate {
    if (_canVibrateCache != null) return _canVibrateCache!;
    try {
      // Calling vibrate(0) is a safe no-op probe that confirms the API exists
      // without actually vibrating.
      web.window.navigator.vibrate(0.toJS);
      _canVibrateCache = true;
    } catch (_) {
      _canVibrateCache = false;
    }
    return _canVibrateCache!;
  }

  void vibrateProximity(Proximity proximity) {
    if (!_canVibrate) return;

    final pattern = _patternFor(proximity);
    if (pattern.isEmpty) return;

    try {
      final jsPattern = pattern.map((ms) => ms.toJS).toList().toJS;
      web.window.navigator.vibrate(jsPattern);
    } catch (_) {
      // Vibration API may throw if the user hasn't interacted with the page.
    }
  }

  void vibrate({required int milliseconds}) {
    if (!_canVibrate || milliseconds <= 0) return;
    try {
      web.window.navigator.vibrate(milliseconds.toJS);
    } catch (_) {}
  }

  void stop() {
    if (!_canVibrate) return;
    try {
      web.window.navigator.vibrate(0.toJS);
    } catch (_) {}
  }

  List<int> _patternFor(Proximity proximity) {
    switch (proximity) {
      case Proximity.immediate:
        // Urgent double-tap.
        return [100, 50, 250, 50, 100];
      case Proximity.close:
        // Two medium pulses.
        return [120, 80, 180];
      case Proximity.nearby:
        // Single light pulse.
        return [100];
      case Proximity.far:
        // No haptics for far-away objects to save battery/attention.
        return [];
    }
  }
}
