import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Speech-to-Text service using the Web Speech API.
///
/// This mirrors the approach used by [TextToSpeechService] — it talks to the
/// browser's `SpeechRecognition` API directly via `package:web`.
class SpeechToTextService {
  static final SpeechToTextService _instance = SpeechToTextService._internal();
  factory SpeechToTextService() => _instance;
  SpeechToTextService._internal();

  web.SpeechRecognition? _recognition;
  bool _isListening = false;
  int _consecutiveErrors = 0;
  bool _shouldRestart = false;

  final _transcriptController = StreamController<String>.broadcast();
  final _statusController = StreamController<SttStatus>.broadcast();

  /// Stream of transcribed text (final results).
  Stream<String> get onTranscript => _transcriptController.stream;

  /// Stream of status changes.
  Stream<SttStatus> get onStatus => _statusController.stream;

  bool get isListening => _isListening;

  /// Whether the browser supports the Web Speech API.
  bool get isSupported {
    try {
      // Feature-detect SpeechRecognition (standard or webkit-prefixed).
      final supported = _hasSpeechRecognition();
      return supported;
    } catch (_) {
      return false;
    }
  }

  bool _hasSpeechRecognition() {
    // Check for standard SpeechRecognition
    final hasStandard =
        globalContext.hasProperty('SpeechRecognition'.toJS).toDart;
    if (hasStandard) return true;

    // Check for webkit-prefixed version (Chrome)
    final hasWebkit =
        globalContext.hasProperty('webkitSpeechRecognition'.toJS).toDart;
    return hasWebkit;
  }

  /// Start listening for speech input.
  void startListening({String lang = 'en-US', bool continuous = true}) {
    if (_isListening) return;

    try {
      _recognition = _createRecognition();
    } catch (e) {
      _statusController.add(SttStatus.unavailable);
      return;
    }

    if (_recognition == null) {
      _statusController.add(SttStatus.unavailable);
      return;
    }

    final recognition = _recognition!;
    recognition.lang = lang;
    recognition.continuous = continuous;
    recognition.interimResults = true;
    recognition.maxAlternatives = 1;
    _shouldRestart = true;

    recognition.onresult = (web.SpeechRecognitionEvent event) {
      final results = event.results;
      final buffer = StringBuffer();

      for (var i = 0; i < results.length; i++) {
        final result = results.item(i);
        final transcript = result.item(0).transcript;
        buffer.write(transcript);
      }

      final text = buffer.toString().trim();
      if (text.isNotEmpty) {
        _transcriptController.add(text);
      }
    }.toJS;

    recognition.onerror = (web.SpeechRecognitionErrorEvent event) {
      final error = event.error;
      // 'no-speech' and 'aborted' are not true errors – they just mean
      // the user hasn't spoken yet or we intentionally stopped.
      if (error == 'no-speech' || error == 'aborted') return;

      // ignore: avoid_print
      print('STT error: $error');

      // Fatal errors: don't auto-restart.
      const fatalErrors = {
        'network',
        'not-allowed',
        'service-not-allowed',
        'audio-capture',
        'bad-grammar',
      };
      if (fatalErrors.contains(error)) {
        _shouldRestart = false;
        _statusController.add(SttStatus.error);
        return;
      }

      // For non-fatal errors, allow limited retries.
      _consecutiveErrors++;
      if (_consecutiveErrors >= 5) {
        _shouldRestart = false;
        _statusController.add(SttStatus.error);
      }
    }.toJS;

    recognition.onstart = (web.Event _) {
      _isListening = true;
      _consecutiveErrors = 0;
      _statusController.add(SttStatus.listening);
    }.toJS;

    recognition.onend = (web.Event _) {
      _isListening = false;
      _statusController.add(SttStatus.stopped);

      // Auto-restart if we're in continuous mode and the reco stopped
      // unexpectedly (Chrome kills it after ~60s of silence).
      if (continuous && _shouldRestart && _recognition != null) {
        Future.delayed(const Duration(seconds: 1), () {
          if (_shouldRestart && _recognition != null) {
            try {
              _recognition!.start();
            } catch (_) {
              // Already started or otherwise unavailable — silently ignore.
            }
          }
        });
      }
    }.toJS;

    try {
      recognition.start();
    } catch (e) {
      _statusController.add(SttStatus.error);
    }
  }

  /// Stop listening.
  void stopListening() {
    final recognition = _recognition;
    _recognition = null; // prevents auto-restart in onend
    _shouldRestart = false;
    _isListening = false;
    _statusController.add(SttStatus.stopped);
    recognition?.stop();
  }

  /// Create a SpeechRecognition instance, handling the webkit prefix.
  web.SpeechRecognition? _createRecognition() {
    try {
      return web.SpeechRecognition();
    } catch (_) {
      // Fallback: try the webkit-prefixed constructor via JS interop.
      try {
        final ctor = globalContext.getProperty('webkitSpeechRecognition'.toJS);
        if (ctor != null) {
          return _callCtor(ctor);
        }
      } catch (_) {}
      return null;
    }
  }

  void dispose() {
    stopListening();
    _transcriptController.close();
    _statusController.close();
  }
}

@JS('Reflect.construct')
external web.SpeechRecognition _callCtor(JSAny ctor);

/// Status states for the STT service.
enum SttStatus {
  /// Currently listening for speech.
  listening,

  /// Stopped (either by user or naturally).
  stopped,

  /// An error occurred.
  error,

  /// Browser doesn't support Web Speech API.
  unavailable,
}
