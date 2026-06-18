import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iris/services/haptics_service.dart';
import 'package:iris/services/obstacle_detection_service.dart';
import 'package:iris/services/tts_service.dart';
import 'package:iris/themes/theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ObstacleDetectionService _detection = ObstacleDetectionService();
  final TextToSpeechService _tts = TextToSpeechService();
  final HapticsService _haptics = HapticsService();

  bool _isLoading = true;
  String? _error;
  String? _viewType;
  ObstacleDetection? _lastDetection;
  bool _alertedImmediate = false;
  bool _alertedClose = false;
  bool _alertedNearby = false;

  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (!_detection.isAvailable) {
        throw StateError(
          'Obstacle detection is not available. Make sure you are running the PWA in a browser.',
        );
      }

      await _detection.loadModel();

      // Register the platform view first so Flutter can insert the container
      // into the DOM before the JS helper looks it up.
      final viewType = _detection.registerView();
      if (mounted) {
        setState(() => _viewType = viewType);
      }

      await _detection.startCamera();

      if (mounted) {
        setState(() => _isLoading = false);
      }

      _tts.speak('Camera active. Scanning for obstacles.');
      _startDetectionLoop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      _tts.speak('Could not start camera.');
    }
  }

  void _startDetectionLoop() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 600),
      (_) => _runDetection(),
    );
  }

  Future<void> _runDetection() async {
    if (!_detection.isRunning) return;

    final detection = await _detection.detect();
    if (!mounted) return;

    setState(() => _lastDetection = detection);

    if (detection == null) {
      // Reset alert latches when the frame clears.
      _alertedImmediate = false;
      _alertedClose = false;
      _alertedNearby = false;
      return;
    }

    _haptics.vibrateProximity(detection.proximity);

    switch (detection.proximity) {
      case Proximity.immediate:
        if (!_alertedImmediate) {
          _tts.speak(proximityAnnouncement(detection.proximity, detection.label));
          _alertedImmediate = true;
          _alertedClose = true;
          _alertedNearby = true;
        }
      case Proximity.close:
        if (!_alertedClose) {
          _tts.speak(proximityAnnouncement(detection.proximity, detection.label));
          _alertedClose = true;
          _alertedNearby = true;
          _alertedImmediate = false;
        }
      case Proximity.nearby:
        if (!_alertedNearby) {
          _tts.speak(proximityAnnouncement(detection.proximity, detection.label));
          _alertedNearby = true;
          _alertedClose = false;
          _alertedImmediate = false;
        }
      case Proximity.far:
        // Reset latches so we alert again when the object gets closer.
        _alertedImmediate = false;
        _alertedClose = false;
        _alertedNearby = false;
    }
  }

  void _close() {
    _detectionTimer?.cancel();
    _detection.stop();
    _tts.stop();
    _haptics.stop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _detection.stop();
    _tts.stop();
    _haptics.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview via HtmlElementView.
          if (_viewType != null)
            HtmlElementView(viewType: _viewType!)
          else
            const Center(
              child: CircularProgressIndicator(color: kPrimaryAccent),
            ),

          // Status overlay.
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                _buildBottomPanel(),
              ],
            ),
          ),

          // Loading / error overlays.
          if (_isLoading || _error != null)
            Container(
              color: Colors.black87,
              child: Center(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _close,
                              child: const Text('Go back'),
                            ),
                          ],
                        ),
                      )
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: kPrimaryAccent),
                          SizedBox(height: 16),
                          Text(
                            'Starting camera and loading model...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _close,
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black38,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors, color: kPrimaryAccent, size: 16),
                SizedBox(width: 6),
                Text(
                  'Obstacle detection active',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    final detection = _lastDetection;
    final proximity = detection?.proximity;

    Color panelColor;
    String statusText;
    IconData statusIcon;

    switch (proximity) {
      case Proximity.immediate:
        panelColor = Colors.redAccent;
        statusText = 'Obstacle very close – stop';
        statusIcon = Icons.warning_amber_rounded;
      case Proximity.close:
        panelColor = Colors.orangeAccent;
        statusText = 'Obstacle close ahead';
        statusIcon = Icons.notifications_active;
      case Proximity.nearby:
        panelColor = kTertiaryAccent;
        statusText = 'Obstacle nearby';
        statusIcon = Icons.info_outline;
      case Proximity.far:
      case null:
        panelColor = Colors.white10;
        statusText = detection != null
            ? '${detection.label} in the distance'
            : 'No obstacles detected';
        statusIcon = Icons.check_circle_outline;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panelColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: panelColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: panelColor, size: 36),
          const SizedBox(height: 8),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (detection != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${(detection.areaRatio * 100).toStringAsFixed(0)}% of frame · ${(detection.score * 100).toStringAsFixed(0)}% confidence',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
