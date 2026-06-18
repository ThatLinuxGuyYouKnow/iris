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
/// ## Key handling — two modes
///
/// **Proxy mode (production, default):** When no `GEMINI_API_KEY` dart-define
/// is set, the client calls `/api/gemini` — a Netlify serverless function
/// that holds the key server-side and forwards to Gemini. The key never
/// lands in the deployed client bundle.
///
/// **Direct mode (local dev):** When `--dart-define=GEMINI_API_KEY=...` is
/// set, the client calls Gemini REST directly with the key in the URL. This
/// is the fast path for `flutter run` without needing `netlify dev`.
///
/// `isConfigured` is true in either mode (proxy is always configured in
/// production; direct requires the key).
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const String _defaultModel = 'gemini-2.5-flash';
  static const String _endpointBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Proxy endpoint served by `netlify/functions/gemini.js`. Relative URL so
  /// it works on any origin (Netlify, `netlify dev`, or a local proxy).
  static const String _proxyEndpoint = '/api/gemini';

  /// Read once at compile time from `--dart-define=GEMINI_API_KEY=...`.
  /// Empty by default so the app compiles key-less for layout testing and
  /// falls through to proxy mode in production.
  static const String _apiKeyFromEnv =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Fallback key source for dev: a non-committed file at runtime. Left as a
  /// hook; the primary path is the dart-define above.
  static String? _runtimeKeyOverride;

  /// Lets a dev tool inject a key at runtime (e.g. from a non-committed
  /// config) without rebuilding. Prefer `--dart-define` in production.
  static void setRuntimeKeyOverride(String? key) => _runtimeKeyOverride = key;

  String get _apiKey => _runtimeKeyOverride ?? _apiKeyFromEnv;

  /// True when either mode is available: proxy (always, in production) or
  /// direct (when a key is set).
  bool get isConfigured => true;

  /// True when the client will call Gemini directly (local dev path).
  bool get _useDirectMode => _apiKey.isNotEmpty;

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
  /// speak via [TextToSpeechService]. Throws if the API returns an error;
  /// callers should catch and degrade gracefully.
  Future<String> describeScene(
    String base64Jpeg, {
    String userPrompt =
        'Describe what is immediately around me so I can walk safely.',
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final body = {
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
    };

    final resp = await _postGenerateContent(body, timeout: timeout);
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
    final body = {
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
    };

    final resp = await _postGenerateContent(body, timeout: timeout);
    final text = _extractText(resp);
    final sources = _extractGroundingSources(resp);
    return GroundedAnswer(text: text.trim(), sources: sources);
  }

  /// Shared transport: sends a generateContent body to Gemini, either
  /// directly (local dev with key) or via the serverless proxy (production).
  /// Both paths return the same Gemini response shape.
  Future<http.Response> _postGenerateContent(
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final jsonBody = jsonEncode(body);
    const headers = {'Content-Type': 'application/json'};

    if (_useDirectMode) {
      final uri = Uri.parse(
          '$_endpointBase/$_model:generateContent?key=$_apiKey');
      return http
          .post(uri, headers: headers, body: jsonBody)
          .timeout(timeout);
    }

    // Proxy mode: wrap the body with the model name and POST to the
    // serverless function. The proxy adds the key server-side.
    final wrapped = jsonEncode({'model': _model, 'body': body});
    return http
        .post(Uri.parse(_proxyEndpoint), headers: headers, body: wrapped)
        .timeout(timeout);
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
