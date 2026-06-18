import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

/// Dart interop for the obstacle-detection API exposed by
/// `web/obstacle_detection.js`.
@JS('irisObstacleDetection')
external IrisObstacleDetection? get _irisObstacleDetection;

extension type IrisObstacleDetection(JSObject _) implements JSObject {
  external JSPromise<JSAny?> loadModel();
  external JSPromise<JSAny?> startCamera(JSString containerId);
  external JSPromise<JSAny?> detectObstacle();
  external JSString? captureFrame(num quality);
  external void stopCamera();
}

/// Result of a single obstacle-detection frame.
class ObstacleDetection {
  final String label;
  final double score;
  final double areaRatio;
  final List<double> bbox;
  final Size frameSize;

  const ObstacleDetection({
    required this.label,
    required this.score,
    required this.areaRatio,
    required this.bbox,
    required this.frameSize,
  });

  /// How "close" the obstacle probably is, based on how much of the frame it
  /// occupies. This is a heuristic: a larger object in the frame is usually
  /// nearer to the camera.
  Proximity get proximity {
    if (areaRatio >= 0.45) return Proximity.immediate;
    if (areaRatio >= 0.2) return Proximity.close;
    if (areaRatio >= 0.08) return Proximity.nearby;
    return Proximity.far;
  }
}

enum Proximity { far, nearby, close, immediate }

/// Service that manages the camera preview and COCO-SSD obstacle detection.
class ObstacleDetectionService {
  static final ObstacleDetectionService _instance =
      ObstacleDetectionService._internal();
  factory ObstacleDetectionService() => _instance;
  ObstacleDetectionService._internal();

  String? _viewType;
  Completer<void>? _viewReady;
  bool _modelLoaded = false;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  bool get isAvailable => _api != null;

  IrisObstacleDetection? get _api => _irisObstacleDetection;

  /// Pre-load the COCO-SSD model so the first detection is fast.
  Future<void> loadModel() async {
    final api = _api;
    if (api == null) {
      throw StateError('Obstacle detection JS API is not available');
    }
    if (_modelLoaded) return;
    await api.loadModel().toDart;
    _modelLoaded = true;
  }

  /// Register a platform view that will host the camera preview.
  ///
  /// Call this first, then use the returned [viewType] with an
  /// [HtmlElementView]. Once the widget is built, call [startCamera].
  String registerView() {
    _viewType = 'iris-camera-${DateTime.now().millisecondsSinceEpoch}';
    _viewReady = Completer<void>();

    final container = web.HTMLDivElement()
      ..id = _viewType!
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.overflow = 'hidden';

    ui_web.platformViewRegistry.registerViewFactory(_viewType!, (int viewId) {
      _viewReady?.complete();
      return container;
    });

    return _viewType!;
  }

  /// Start the camera after the platform view has been inserted into the DOM.
  ///
  /// This waits for the [HtmlElementView] factory callback to fire, ensuring
  /// the container element exists in the document before the JS helper tries
  /// to attach the `<video>` element.
  Future<Size> startCamera() async {
    final api = _api;
    if (api == null) {
      throw StateError('Obstacle detection JS API is not available');
    }
    if (_viewType == null || _viewReady == null) {
      throw StateError('registerView() must be called before startCamera()');
    }

    // Wait until Flutter has built the HtmlElementView and inserted the
    // container into the DOM.
    await _viewReady!.future;

    final result = await api.startCamera(_viewType!.toJS).toDart;
    _isRunning = true;

    // Parse the returned frame dimensions so callers can reason about the
    // preview size if needed.
    final dimensions = _parseJson(result);
    debugPrint(
      'Camera started: ${dimensions['width']}x${dimensions['height']}',
    );

    return Size(
      (dimensions['width'] as num?)?.toDouble() ?? 640,
      (dimensions['height'] as num?)?.toDouble() ?? 480,
    );
  }

  /// Run a single detection frame. Returns `null` if nothing is detected.
  Future<ObstacleDetection?> detect() async {
    final api = _api;
    if (api == null || !_isRunning) return null;

    final result = await api.detectObstacle().toDart;
    if (result == null) return null;

    final json = _parseJson(result);
    final bbox = (json['bbox'] as List<dynamic>)
        .cast<num>()
        .map((n) => n.toDouble())
        .toList();
    final frameWidth = (json['frameWidth'] as num).toDouble();
    final frameHeight = (json['frameHeight'] as num).toDouble();

    return ObstacleDetection(
      label: json['class'] as String,
      score: (json['score'] as num).toDouble(),
      areaRatio: (json['areaRatio'] as num).toDouble(),
      bbox: bbox,
      frameSize: Size(frameWidth, frameHeight),
    );
  }

  /// Stop the camera and release resources.
  void stop() {
    final api = _api;
    if (api == null) return;
    api.stopCamera();
    _isRunning = false;
    _viewType = null;
  }

  /// Capture a single frame from the live camera as a base64 JPEG data URL
  /// (e.g. `data:image/jpeg;base64,...`). Returns `null` when the camera
  /// isn't running or the frame isn't ready. Used to feed Gemini Vision.
  String? captureFrame({double quality = 0.7}) {
    final api = _api;
    if (api == null || !_isRunning) return null;
    final dataUrl = api.captureFrame(quality);
    if (dataUrl == null) return null;
    return dataUrl.toDart;
  }

  /// Like [captureFrame] but returns only the raw base64 bytes (no
  /// `data:image/jpeg;base64,` prefix), which is what the Gemini REST API
  /// expects in `inline_data.data`.
  String? captureFrameBase64({double quality = 0.7}) {
    final url = captureFrame(quality: quality);
    if (url == null) return null;
    final comma = url.indexOf(',');
    return comma < 0 ? url : url.substring(comma + 1);
  }

  Map<String, dynamic> _parseJson(JSAny? value) {
    if (value == null) return {};
    final text = value.toString();
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

/// Format a proximity value as a human-friendly announcement.
String proximityAnnouncement(Proximity proximity, String label) {
  switch (proximity) {
    case Proximity.immediate:
      return 'Warning! $label very close. Stop.';
    case Proximity.close:
      return '$label close ahead. Slow down.';
    case Proximity.nearby:
      return '$label nearby.';
    case Proximity.far:
      return '$label detected in the distance.';
  }
}
