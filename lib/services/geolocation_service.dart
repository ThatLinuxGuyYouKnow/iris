import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// A single GPS reading from the browser.
class GeoPosition {
  final double latitude;
  final double longitude;
  final double accuracyMetres;
  final double? headingDegrees;
  final DateTime timestamp;

  const GeoPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    this.headingDegrees,
    required this.timestamp,
  });

  @override
  String toString() =>
      'GeoPosition(${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)} '
      '±${accuracyMetres.toStringAsFixed(0)}m)';
}

/// Browser geolocation wrapper built on `package:web`, mirroring the approach
/// used by [HapticsService] and the STT/TTS services. Web-only by design —
/// Iris currently ships as a PWA. The browser supplies the device GPS; no
/// model or API key is involved (Gemini does NOT know the user's location
/// unless this service pipes it in).
class GeolocationService {
  static final GeolocationService _instance = GeolocationService._internal();
  factory GeolocationService() => _instance;
  GeolocationService._internal();

  /// `navigator.geolocation` is non-nullable in package:web's bindings, so
  /// feature detection is a try/catch rather than a null probe.
  bool get isSupported {
    try {
      // Accessing the property can throw on unsupported/embedded views.
      web.window.navigator.geolocation;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// One-shot position fix. Throws if the user denies permission or the
  /// browser doesn't support geolocation. `highAccuracy` requests GPS-grade
  /// fixes (slower, may fail indoors).
  Future<GeoPosition> getPosition({bool highAccuracy = true}) {
    final completer = Completer<GeoPosition>();
    final geo = web.window.navigator.geolocation;

    void onSuccess(web.GeolocationPosition pos) {
      final c = pos.coords;
      completer.complete(GeoPosition(
        latitude: c.latitude,
        longitude: c.longitude,
        accuracyMetres: c.accuracy,
        // `heading` is `double?` and may be NaN when stationary; only pass
        // it through when it is a finite number.
        headingDegrees:
            (c.heading?.isFinite ?? false) ? c.heading : null,
        timestamp: DateTime.fromMillisecondsSinceEpoch(pos.timestamp),
      ));
    }

    void onError(web.GeolocationPositionError err) {
      completer.completeError(GeolocationException(
        code: err.code,
        // `message` is already a Dart String in package:web 1.1.1.
        message: err.message,
      ));
    }

    geo.getCurrentPosition(
      onSuccess.toJS,
      onError.toJS,
      web.PositionOptions(
        enableHighAccuracy: highAccuracy,
        timeout: 15000,
        maximumAge: 0,
      ),
    );

    return completer.future;
  }

  /// Continuous position updates. Emits until the stream is cancelled. Errors
  /// (e.g. permission revoked mid-watch) are forwarded but do not close it.
  Stream<GeoPosition> watchPosition({bool highAccuracy = true}) {
    final controller = StreamController<GeoPosition>.broadcast();
    final geo = web.window.navigator.geolocation;

    void onSuccess(web.GeolocationPosition pos) {
      final c = pos.coords;
      controller.add(GeoPosition(
        latitude: c.latitude,
        longitude: c.longitude,
        accuracyMetres: c.accuracy,
        headingDegrees:
            (c.heading?.isFinite ?? false) ? c.heading : null,
        timestamp: DateTime.fromMillisecondsSinceEpoch(pos.timestamp),
      ));
    }

    void onError(web.GeolocationPositionError err) {
      controller.addError(GeolocationException(
        code: err.code,
        message: err.message,
      ));
    }

    final watchId = geo.watchPosition(
      onSuccess.toJS,
      onError.toJS,
      web.PositionOptions(
        enableHighAccuracy: highAccuracy,
        timeout: 20000,
        maximumAge: 5000,
      ),
    );

    controller.onCancel = () {
      geo.clearWatch(watchId);
      controller.close();
    };

    return controller.stream;
  }
}

/// Thrown when the browser fails to return a position. `code` mirrors the
/// W3C GeolocationPositionError codes: 1=permission denied, 2=position
/// unavailable, 3=timeout.
class GeolocationException implements Exception {
  final int code;
  final String message;
  const GeolocationException({required this.code, required this.message});

  String get humanDescription => switch (code) {
        1 => 'Location permission denied. Allow location access and try again.',
        2 => 'Position unavailable. Check your device GPS or network.',
        3 => 'Location request timed out. Try again in an open area.',
        _ => 'Location error: $message',
      };

  @override
  String toString() => 'GeolocationException($code): $message';
}
