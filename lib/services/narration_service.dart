import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class NarrationException implements Exception {
  final String message;
  const NarrationException(this.message);
  @override
  String toString() => 'NarrationException: $message';
}

class NarrationService {
  static final NarrationService _instance = NarrationService._internal();
  factory NarrationService() => _instance;
  NarrationService._internal();

  static const String _endpoint =
      'https://opencode.ai/zen/go/v1/chat/completions';
  static const String _model = 'mimo-v2.5-pro';
  static const String _proxyEndpoint = '/api/narration';

  static const String _apiKeyFromEnv = String.fromEnvironment(
    'OPENCODE_API_KEY',
    defaultValue: '',
  );

  static String? _runtimeKeyOverride;

  static void setRuntimeKeyOverride(String? key) => _runtimeKeyOverride = key;

  String get _apiKey => _runtimeKeyOverride ?? _apiKeyFromEnv;

  bool get isConfigured => true;

  bool get _useDirectMode => _apiKey.isNotEmpty;

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

  Future<String> describeScene(
    String base64Jpeg, {
    String userPrompt =
        'Describe what is immediately around me so I can walk safely.',
    String? groundingContext,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final grounding = groundingContext?.trim() ?? '';
    final prompt = grounding.isEmpty
        ? userPrompt
        : '''$userPrompt

Map context from GPS/reverse geocode: $grounding
Use this only as location context. Do not claim a building or sign is visible unless it is readable in the image.''';

    final messages = [
      {'role': 'system', 'content': _visionSystemInstruction},
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Jpeg'},
          },
        ],
      },
    ];

    final body = {'messages': messages, 'temperature': 0.2, 'max_tokens': 1000};

    final resp = await _post(body, timeout: timeout);
    final text = _extractText(resp);
    return text.trim();
  }

  Future<http.Response> _post(
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final jsonBody = jsonEncode(body);
    const headers = {'Content-Type': 'application/json'};

    if (_useDirectMode) {
      final payload = {...body, 'model': _model};
      return http
          .post(
            Uri.parse(_endpoint),
            headers: {...headers, 'Authorization': 'Bearer $_apiKey'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);
    }

    return http
        .post(Uri.parse(_proxyEndpoint), headers: headers, body: jsonBody)
        .timeout(timeout);
  }

  String _extractText(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw NarrationException(
        'Narration API error ${resp.statusCode}: ${resp.body}',
      );
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      return "I can't see clearly right now.";
    }
    final content = choices[0]['message']?['content'];
    if (content is String) {
      final out = content.trim();
      return out.isEmpty ? "I can't see clearly right now." : out;
    }
    if (content is List) {
      final buf = StringBuffer();
      for (final p in content) {
        if (p is Map<String, dynamic> && p['text'] is String) {
          buf.write(p['text']);
        }
      }
      final out = buf.toString().trim();
      return out.isEmpty ? "I can't see clearly right now." : out;
    }
    return "I can't see clearly right now.";
  }
}
