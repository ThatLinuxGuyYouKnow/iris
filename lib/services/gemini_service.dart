import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A Google Maps source citation returned by Grounding with Google Maps.
/// The Maps ToS requires these to be displayed alongside the grounded text
/// (see [MapsAttribution] widget).
class GroundingSource {
  final String title;
  final String uri;
  final String? placeId;

  const GroundingSource({
    required this.title,
    required this.uri,
    this.placeId,
  });

  factory GroundingSource.fromMap(Map<String, dynamic> map) {
    final maps = (map['maps'] as Map<String, dynamic>?) ?? {};
    return GroundingSource(
      title: (maps['title'] as String?) ?? 'Google Maps',
      uri: (maps['uri'] as String?) ?? (maps['googleMapsUri'] as String?) ?? '',
      placeId: maps['placeId'] as String?,
    );
  }
}

/// Result of a Gemini grounded place query. [text] is the model's answer;
/// [sources] are the Maps citations that MUST be rendered per Google's
/// attribution guidelines.
class GroundedAnswer {
  final String text;
  final List<GroundingSource> sources;

  const GroundedAnswer({required this.text, required this.sources});

  bool get hasSources => sources.isNotEmpty;
}

/// Gemini 2.5 Flash client for the two AI layers Iris uses:
///   1. [describeScene] — vision: camera frame -> short spoken scene
///      description. Strict anti-hallucination system instruction so the
///      model never fabricates landmarks (the life-safety failure mode the
///      winning pitch identified).
///   2. [groundedPlaceQuery] — text + Grounding with Google Maps tool:
///      takes the user's GPS (supplied by [GeolocationService]) as input and
///      answers place/entrance questions with Maps citations.
///
/// Vision and Maps grounding CANNOT be the same call — the Maps tool does
/// not accept multimodal input — so the two run as parallel requests and are
/// merged by [SceneMerger].
///
/// The API key is read from `--dart-define=GEMINI_API_KEY=...` so it never
/// lands in the repo. Call `isConfigured` to check at runtime.
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const String _defaultModel = 'gemini-2.5-flash';
  static const String _endpointBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Read once at compile time from `--dart-define=GEMINI_API_KEY=...`.
  /// Empty by default so the app compiles key-less for layout testing.
  static const String _apiKeyFromEnv =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Fallback key source for dev: a non-committed file at runtime. Left as a
  /// hook; the primary path is the dart-define above.
  static String? _runtimeKeyOverride;

  /// Lets a dev tool inject a key at runtime (e.g. from a non-committed
  /// config) without rebuilding. Prefer `--dart-define` in production.
  static void setRuntimeKeyOverride(String? key) => _runtimeKeyOverride = key;

  String get _apiKey => _runtimeKeyOverride ?? _apiKeyFromEnv;
  bool get isConfigured => _apiKey.isNotEmpty;

  String get _model => _defaultModel;

  /// Strict system instruction that prevents the model from inventing
  /// landmarks or distances — the guardrail behind the safety-override pitch.
  static const String _visionSystemInstruction = '''
You are a navigation assistant for a visually impaired walker on a university campus.
Describe ONLY what is concretely visible in the image.
- Never fabricate landmarks, signs, or place names you cannot read in the image.
- Give distances only as rough estimates (within 1m, 3m, 5m, or 10m+). If you cannot estimate, do not give a distance.
- If you are uncertain about an object, say "possibly <x>" or omit it.
- If the image is unclear or too dark, reply exactly: "I can't see clearly right now."
- Prioritise obstacles, stairs, kerbs, doors, construction, and readable signage.
- Keep the whole reply under 60 words, in plain spoken English, no preamble.
''';

  /// Vision call: a single JPEG frame -> a short scene description safe to
  /// speak via [TextToSpeechService]. Throws if not configured or the API
  /// returns an error; callers should catch and degrade gracefully.
  Future<String> describeScene(
    String base64Jpeg, {
    String userPrompt =
        'Describe what is immediately around me so I can walk safely.',
    Duration timeout = const Duration(seconds: 8),
  }) async {
    _requireKey();
    final uri = Uri.parse('$_endpointBase/$_model:generateContent?key=$_apiKey');
    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _visionSystemInstruction},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Jpeg,
              },
            },
            {'text': userPrompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 200,
        'topP': 0.9,
      },
    });

    final resp = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(timeout);
    final text = _extractText(resp);
    return text.trim();
  }

  /// Grounded call: a place/entrance question + the user's GPS -> an answer
  /// grounded in Google Maps, with citations. The [latitude]/[longitude]
  /// come from [GeolocationService] — Gemini does NOT locate the user on its
  /// own; the device supplies the coordinate and Gemini searches Maps around
  /// it. Per Google's ToS the returned [GroundingSource]s MUST be displayed.
  Future<GroundedAnswer> groundedPlaceQuery(
    String prompt, {
    required double latitude,
    required double longitude,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    _requireKey();
    final uri = Uri.parse('$_endpointBase/$_model:generateContent?key=$_apiKey');
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      // Turn on Grounding with Google Maps.
      'tools': [
        {'googleMaps': {}},
      ],
      // Feed the device-supplied GPS as the search context.
      'toolConfig': {
        'retrievalConfig': {
          'latLng': {
            'latitude': latitude,
            'longitude': longitude,
          },
        },
      },
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 300,
      },
    });

    final resp = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(timeout);

    final text = _extractText(resp);
    final sources = _extractGroundingSources(resp);
    return GroundedAnswer(text: text.trim(), sources: sources);
  }

  void _requireKey() {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Gemini API key not set. Run with '
        '--dart-define=GEMINI_API_KEY=<your-key> '
        'or call GeminiService.setRuntimeKeyOverride(...).',
      );
    }
  }

  String _extractText(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw GeminiException(
        'Gemini API error ${resp.statusCode}: ${resp.body}',
      );
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      // Prompt feedback / blocked — surface a safe, non-hallucinated message.
      final feedback = json['promptFeedback']?['blockReason'];
      if (feedback != null) {
        throw GeminiException('Response blocked: $feedback');
      }
      return "I can't see clearly right now.";
    }
    final parts = (candidates[0]['content']?['parts'] as List<dynamic>?) ?? [];
    final buf = StringBuffer();
    for (final p in parts) {
      if (p is Map<String, dynamic> && p['text'] is String) buf.write(p['text']);
    }
    final out = buf.toString().trim();
    return out.isEmpty ? "I can't see clearly right now." : out;
  }

  List<GroundingSource> _extractGroundingSources(http.Response resp) {
    try {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return const [];
      final meta =
          candidates[0]['groundingMetadata'] as Map<String, dynamic>?;
      final chunks = meta?['groundingChunks'] as List<dynamic>?;
      if (chunks == null) return const [];
      return chunks
          .whereType<Map<String, dynamic>>()
          .map(GroundingSource.fromMap)
          .where((s) => s.uri.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);
  @override
  String toString() => 'GeminiException: $message';
}
