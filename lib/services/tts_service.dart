import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  bool _voicesReady = false;
  final _voicesController =
      StreamController<List<web.SpeechSynthesisVoice>>.broadcast();

  void _loadVoices() {
    try {
      final voices = web.window.speechSynthesis.getVoices();
      if (voices.length > 0) {
        _voicesReady = true;
        _voicesController.add(voices.toDart);
      }
    } catch (e) {
      print('Error loading voices: $e');
    }
  }

  Future<List<web.SpeechSynthesisVoice>> _ensureVoices() async {
    try {
      if (_voicesReady) {
        return web.window.speechSynthesis.getVoices().toDart;
      }

      // Voices may not be available immediately on Chrome.
      web.window.speechSynthesis.onvoiceschanged = (web.Event event) {
        _loadVoices();
      }.toJS;

      // Try loading them now in case they're already there.
      _loadVoices();

      return await _voicesController.stream.first;
    } catch (e) {
      print('Error ensuring voices: $e');
      return [];
    }
  }

  Future<void> speak(String text, {String lang = 'en-US'}) async {
    try {
      if (text.trim().isEmpty) return;

      final synthesis = web.window.speechSynthesis;
      synthesis.cancel();

      final voices = await _ensureVoices();

      final utterance = web.SpeechSynthesisUtterance(text);
      utterance.lang = lang;
      utterance.rate = 1.0;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;

      // Pick the best matching voice, fallback to any available voice.
      web.SpeechSynthesisVoice? selectedVoice;
      for (final voice in voices) {
        if (voice.lang.startsWith(lang)) {
          selectedVoice = voice;
          break;
        }
      }
      selectedVoice ??= voices.isNotEmpty ? voices.first : null;

      if (selectedVoice != null) {
        utterance.voice = selectedVoice;
      }

      utterance.onerror = (web.Event event) {
        try {
          final errorEvent = event as web.SpeechSynthesisErrorEvent;
          print('TTS error: ${errorEvent.error}');
        } catch (e) {
          print('Error handling TTS error: $e');
        }
      }.toJS;

      synthesis.speak(utterance);
    } catch (e) {
      print('Error in speak: $e');
    }
  }

  void stop() {
    try {
      web.window.speechSynthesis.cancel();
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }
}
