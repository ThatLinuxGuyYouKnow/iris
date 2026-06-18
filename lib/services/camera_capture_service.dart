import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// One-shot camera capture for the "Where am I?" flow. Unlike
/// [ObstacleDetectionService], this does NOT load COCO-SSD or mount a
/// platform view — it just grabs a single JPEG frame from the rear camera
/// and immediately releases the stream. Used to feed Gemini Vision when the
/// user isn't already on the camera screen.
///
/// Web-only by design (matches the rest of Iris's `package:web` services).
class CameraCaptureService {
  static final CameraCaptureService _instance = CameraCaptureService._internal();
  factory CameraCaptureService() => _instance;
  CameraCaptureService._internal();

  bool get isSupported {
    try {
      web.window.navigator.mediaDevices;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Grab one JPEG frame from the rear camera and return it as raw base64
  /// (no data-URL prefix — exactly what [GeminiService.describeScene] wants).
  /// Returns `null` if no camera/permission. Always releases the stream.
  Future<String?> captureJpegBase64({
    double quality = 0.7,
    Duration readyTimeout = const Duration(seconds: 4),
  }) async {
    if (!isSupported) return null;

    web.MediaStream? stream;
    web.HTMLVideoElement? video;
    try {
      // `MediaStreamConstraints.video/audio` are typed as `JSAny` in
      // package:web 1.1.1, so the boolean and the constraint set both need
      // to be lifted to JS values.
      final constraints = web.MediaStreamConstraints(
        video: web.MediaTrackConstraintSet(
          facingMode: 'environment'.toJS,
          width: 640.toJS,
          height: 480.toJS,
        ),
        audio: false.toJS,
      );
      stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;

      video = web.document.createElement('video') as web.HTMLVideoElement
        ..srcObject = stream
        ..autoplay = true
        ..muted = true
        ..playsInline = true;

      await video.play().toDart;

      // Wait until the first frame is decoded and dimensions are known.
      final ready = Completer<void>();
      void onLoaded() {
        if (!ready.isCompleted) ready.complete();
      }
      video.onloadeddata = onLoaded.toJS;
      if (video.readyState >= 2) onLoaded();
      await ready.future.timeout(readyTimeout);

      final canvas =
          web.document.createElement('canvas') as web.HTMLCanvasElement
            ..width = video.videoWidth
            ..height = video.videoHeight;
      final ctx = canvas.getContext('2d');
      if (ctx == null) return null;
      final ctx2d = ctx as web.CanvasRenderingContext2D;
      ctx2d.drawImage(video, 0, 0, canvas.width, canvas.height);

      // toDataURL returns a Dart String already in package:web 1.1.1.
      final dataUrl = canvas.toDataURL('image/jpeg', quality.toJS);
      final comma = dataUrl.indexOf(',');
      return comma < 0 ? dataUrl : dataUrl.substring(comma + 1);
    } catch (_) {
      return null;
    } finally {
      // Always release the camera so the indicator turns off immediately.
      try {
        video?.pause();
        video?.srcObject = null;
      } catch (_) {}
      try {
        stream?.getTracks().toDart.forEach((t) => t.stop());
      } catch (_) {}
    }
  }
}
