import 'package:flutter/material.dart';
import 'package:iris/screens/camera_screen.dart';
import 'package:iris/screens/route_screen.dart';
import 'package:iris/services/camera_capture_service.dart';
import 'package:iris/services/geolocation_service.dart';
import 'package:iris/services/narration_service.dart';
import 'package:iris/services/reverse_geocode_service.dart';
import 'package:iris/services/routing/campus_graph.dart';
import 'package:iris/services/routing/sample_campus.dart';
import 'package:iris/services/scene_merge.dart';
import 'package:iris/services/stt_service.dart';
import 'package:iris/services/tts_service.dart';
import 'package:iris/themes/theme.dart';
import 'package:iris/widgets/maps_attribution.dart';
import 'package:iris/widgets/open_camera_view.dart';
import 'package:iris/widgets/start_audio_widget.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechToTextService _sttService = SpeechToTextService();
  final TextToSpeechService _tts = TextToSpeechService();
  final GeolocationService _geo = GeolocationService();
  final CameraCaptureService _camera = CameraCaptureService();
  final NarrationService _narration = NarrationService();
  final ReverseGeocodeService _reverseGeocode = ReverseGeocodeService();
  final CampusGraph _graph = loadCampusGraph();

  String _transcript = '';
  SttStatus _sttStatus = SttStatus.stopped;

  // "Where am I?" state
  bool _whereAmIBusy = false;
  SceneReport? _lastReport;
  GeoPosition? _lastFix;

  @override
  void initState() {
    super.initState();
    _sttService.onTranscript.listen((text) {
      if (mounted) {
        setState(() => _transcript = text);
      }
    });
    _sttService.onStatus.listen((status) {
      if (mounted) {
        setState(() => _sttStatus = status);
      }
    });
  }

  @override
  void dispose() {
    if (_sttService.isListening) {
      _sttService.stopListening();
    }
    super.dispose();
  }

  void _toggleListening() {
    if (_sttService.isListening) {
      _sttService.stopListening();
    } else {
      setState(() => _transcript = ''); // Clear old transcript on restart
      _sttService.startListening();
      _tts.speak("Listening.");
    }
  }

  /// The three-layer "Where am I?" flow:
  ///   1. Device GPS (navigator.geolocation) -> lat/lng + accuracy
  ///   2. Kimi K2.6 Vision (camera frame) -> immediate surroundings
  ///   3. RapidAPI reverse geocode (lat/lng) -> place context
  /// Reverse geocode runs before Kimi when available so the thinking model can
  /// turn the place context + camera frame into one usable narration. The
  /// human-verified audio cue is the floor.
  Future<void> _whereAmI() async {
    if (_whereAmIBusy) return;
    setState(() => _whereAmIBusy = true);
    _tts.speak('Getting your location and surroundings.');

    try {
      // 1. Device GPS — the source of truth for "where am I".
      //    NOT locate the user; this coordinate is piped into grounding.
      final fix = await _geo.getPosition(highAccuracy: true);
      if (!mounted) return;
      setState(() => _lastFix = fix);

      // 2. One camera frame for Kimi K2.6 Vision. Released immediately.
      final frame = await _camera.captureJpegBase64();

      // 3. Graph fallback: nearest surveyed waypoint's label as a
      //    non-hallucinated cue when vision is unavailable.
      final nearest = _graph.nearestNode(LatLng(fix.latitude, fix.longitude));
      final graphFallback =
          'You are near ${nearest.label}, a known campus waypoint.';

      // 4. Get reverse geocode first, then pass that context with the frame to
      //    Kimi so the final narration is generated from both signals.
      final visionCall = frame == null
          ? () async => throw StateError('camera unavailable')
          : () => _narration.describeScene(frame);
      final report = await const SceneMerger().compose(
        visionCall: visionCall,
        groundedVisionCall: frame == null
            ? (_) async => throw StateError('camera unavailable')
            : (grounding) => _narration.describeScene(
                frame,
                groundingContext: grounding?.text ?? graphFallback,
              ),
        groundingCall: () =>
            _reverseGeocode.reverseGeocode(fix.latitude, fix.longitude),
        graphFallback: graphFallback,
      );

      if (!mounted) return;
      setState(() => _lastReport = report);
      _tts.speak(report.spokenText);
    } on GeolocationException catch (e) {
      if (!mounted) return;
      _tts.speak(e.humanDescription);
      setState(
        () => _lastReport = SceneReport(
          spokenText: e.humanDescription,
          sources: const [],
          layersUsed: const {Layer.gps},
          degraded: true,
          fallbackNote: 'geolocation: ${e.code}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg =
          'I can\'t get a reading right now. '
          'Use the human-verified audio cue.';
      _tts.speak(msg);
      setState(
        () => _lastReport = SceneReport(
          spokenText: msg,
          sources: const [],
          layersUsed: const {Layer.gps},
          degraded: true,
          fallbackNote: '$e',
        ),
      );
    } finally {
      if (mounted) setState(() => _whereAmIBusy = false);
    }
  }

  String _getStatusText() {
    if (!_sttService.isSupported) {
      return 'Voice recognition not supported';
    }
    switch (_sttStatus) {
      case SttStatus.listening:
        return 'Listening for commands...';
      case SttStatus.error:
        return 'Microphone error. Tap to retry.';
      case SttStatus.unavailable:
        return 'Speech recognition unavailable.';
      case SttStatus.stopped:
        return 'Tap or say a command';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(color: kBackground),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Iris',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryAccent,
                  fontSize: 64,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How can I help you get\nsomewhere today?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),

              // Transcript Display
              if (_transcript.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: kGlassDecoration(),
                  child: Text(
                    '"$_transcript"',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: kPrimaryAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),

              StartAudioCaptureWidget(
                buttonText: 'Use voice controls',
                onButtonPressed: _toggleListening,
                isListening: _sttStatus == SttStatus.listening,
              ),

              const SizedBox(height: 30),

              Text(
                _getStatusText(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _sttStatus == SttStatus.error
                      ? Colors.redAccent
                      : kTextSecondary,
                ),
              ),

              const SizedBox(height: 40),

              OpenCameraView(
                onButtonPressed: () {
                  _tts.speak('Starting camera. Please wait.');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CameraScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),

              OpenCameraView(
                onButtonPressed: () {
                  _tts.speak('Opening routing map.');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RouteScreen()),
                  );
                },
                icon: Icons.map_outlined,
                label: 'Plan a route',
              ),

              const SizedBox(height: 16),

              OpenCameraView(
                onButtonPressed: _whereAmIBusy ? null : _whereAmI,
                icon: Icons.my_location,
                label: _whereAmIBusy ? 'Locating…' : 'Where am I?',
              ),
              const SizedBox(height: 12),
              _cameraGuidanceCard(),

              if (_lastReport != null) ...[
                const SizedBox(height: 24),
                _sceneReportCard(_lastReport!, _lastFix),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraGuidanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(14),
      decoration: kGlassDecoration(opacity: 0.08, borderRadius: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.center_focus_strong_outlined,
            size: 22,
            color: kPrimaryAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              SceneMerger.cameraRaiseCue,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sceneReportCard(SceneReport report, GeoPosition? fix) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: kGlassDecoration(opacity: 0.08, borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                report.degraded
                    ? Icons.cloud_off_outlined
                    : Icons.check_circle_outline,
                size: 18,
                color: report.degraded ? Colors.orangeAccent : kTertiaryAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  report.degraded
                      ? 'Partial reading — some sources unavailable'
                      : 'Scene reading ready',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              if (fix != null)
                Text(
                  '±${fix.accuracyMetres.toStringAsFixed(0)}m',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.spokenText,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (report.hasSources) ...[
            const SizedBox(height: 6),
            // Mandatory per Google's Grounding with Maps attribution rules.
            MapsAttribution(sources: report.sources),
          ],
        ],
      ),
    );
  }
}
