import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iris/services/gemini_service.dart';

class ReverseGeocodeException implements Exception {
  final String message;
  const ReverseGeocodeException(this.message);
  @override
  String toString() => 'ReverseGeocodeException: $message';
}

class ReverseGeocodeService {
  static final ReverseGeocodeService _instance =
      ReverseGeocodeService._internal();
  factory ReverseGeocodeService() => _instance;
  ReverseGeocodeService._internal();

  static const String _rapidApiEndpoint =
      'https://maps-data.p.rapidapi.com/whatishere.php';
  static const String _rapidApiHost = 'maps-data.p.rapidapi.com';
  static const String _proxyEndpoint = '/api/whereami';

  static const String _apiKeyFromEnv =
      String.fromEnvironment('RAPIDAPI_KEY', defaultValue: '');

  static String? _runtimeKeyOverride;

  static void setRuntimeKeyOverride(String? key) => _runtimeKeyOverride = key;

  String get _apiKey => _runtimeKeyOverride ?? _apiKeyFromEnv;

  bool get isConfigured => true;

  bool get _useDirectMode => _apiKey.isNotEmpty;

  Future<GroundedAnswer> reverseGeocode(
    double lat,
    double lng, {
    String lang = 'en',
    String country = 'ng',
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final body = jsonDecode(
      await _fetch(lat, lng, lang: lang, country: country, timeout: timeout),
    ) as Map<String, dynamic>;

    final spoken = _formatSpokenText(body);

    return GroundedAnswer(text: spoken, sources: const []);
  }

  Future<String> _fetch(
    double lat,
    double lng, {
    required String lang,
    required String country,
    required Duration timeout,
  }) async {
    if (_useDirectMode) {
      final uri = Uri.parse(_rapidApiEndpoint).replace(queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'lang': lang,
        'country': country,
      });
      final resp = await http
          .get(uri, headers: {
            'x-rapidapi-key': _apiKey,
            'x-rapidapi-host': _rapidApiHost,
          })
          .timeout(timeout);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw ReverseGeocodeException(
          'RapidAPI error ${resp.statusCode}: ${resp.body}',
        );
      }
      return resp.body;
    }

    // Proxy mode
    final wrapped = jsonEncode({
      'lat': lat,
      'lng': lng,
      'lang': lang,
      'country': country,
    });
    final resp = await http
        .post(Uri.parse(_proxyEndpoint),
            headers: {'Content-Type': 'application/json'}, body: wrapped)
        .timeout(timeout);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ReverseGeocodeException(
        'Proxy error ${resp.statusCode}: ${resp.body}',
      );
    }
    return resp.body;
  }

  String _formatSpokenText(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      return 'Location found, but no nearby place details are available.';
    }

    final address = (data['address'] as String?)?.trim() ?? '';
    final town = (data['town'] as String?)?.trim() ?? '';
    final places = data['places'] as List<dynamic>? ?? const [];

    final nearby = <String>[];
    for (final p in places.take(3)) {
      if (p is! Map<String, dynamic>) continue;
      final name = (p['name'] as String?)?.trim() ??
          (p['title'] as String?)?.trim() ??
          '';
      final type = (p['type'] as String?)?.trim() ??
          (p['category'] as String?)?.trim() ??
          '';
      final distance = p['distance']?.toString() ?? p['dist']?.toString();

      if (name.isEmpty) continue;
      final buf = StringBuffer(name);
      if (type.isNotEmpty && type != name) {
        buf.write(' ($type)');
      }
      if (distance != null) {
        buf.write(', approximately $distance metres away');
      }
      nearby.add(buf.toString());
    }

    final buffer = StringBuffer();

    if (town.isNotEmpty) {
      buffer.write('You are in $town.');
    } else if (address.isNotEmpty) {
      buffer.write('You are at $address.');
    }

    if (nearby.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write('Nearby: ${nearby.join(', ')}.');
    }

    if (buffer.isEmpty) {
      if (address.isNotEmpty) return 'You are at $address.';
      return 'Location found, but no nearby place details are available.';
    }

    return buffer.toString().trim();
  }
}
