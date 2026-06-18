import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:iris/services/routing/hazard.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

/// A named route saved by the user. The ordered waypoints are stored
/// alongside the metadata as a single JSON document inside a Hive box, so
/// re-hydration is a plain `jsonDecode` and there is no schema migration to
/// manage.
class SavedRoute {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<LatLng> waypoints;

  const SavedRoute({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.waypoints,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'waypoints': waypoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
      };

  factory SavedRoute.fromMap(Map<String, dynamic> map) {
    return SavedRoute(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      waypoints: [
        for (final w in (map['waypoints'] as List).cast<Map<String, dynamic>>())
          LatLng((w['lat'] as num).toDouble(), (w['lng'] as num).toDouble()),
      ],
    );
  }
}

/// Hive-backed store for two concerns:
///   1. `routes` box — user-saved routes for quick re-use.
///   2. `hazards` box — community-reported obstacles that feed
///      `RoutingEngine`'s cost function at query time.
///
/// Hive is used (rather than sqflite) because Iris currently targets the web
/// via `package:web` for STT/TTS/CV, and sqflite does not run on web. Hive's
/// binary backend works on web (IndexedDB), mobile, and desktop with the same
/// code, so the store stays portable if Iris ships native later.
///
/// Singleton: call `await RouteStore.instance.init()` once at startup.
class RouteStore {
  RouteStore._();
  static final RouteStore instance = RouteStore._();

  static const _routesBox = 'iris_routes';
  static const _hazardsBox = 'iris_hazards';

  final _uuid = const Uuid();
  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    await Hive.openBox<String>(_routesBox);
    await Hive.openBox<String>(_hazardsBox);
    _initialised = true;
  }

  Box<String> get _routes => Hive.box<String>(_routesBox);
  Box<String> get _hazards => Hive.box<String>(_hazardsBox);

  // ---- Saved routes --------------------------------------------------------

  Future<String> saveRoute(String name, List<LatLng> waypoints) async {
    final id = _uuid.v4();
    final route = SavedRoute(
      id: id,
      name: name,
      createdAt: DateTime.now(),
      waypoints: waypoints,
    );
    await _routes.put(id, jsonEncode(route.toMap()));
    return id;
  }

  Future<List<SavedRoute>> listRoutes() async {
    final values = _routes.values.toList();
    final routes = <SavedRoute>[];
    for (final v in values) {
      try {
        routes.add(SavedRoute.fromMap(
            jsonDecode(v) as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupt entries rather than crashing the list view.
      }
    }
    routes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return routes;
  }

  Future<void> deleteRoute(String id) => _routes.delete(id);

  // ---- Hazards -------------------------------------------------------------

  Future<String> addHazard(Hazard hazard) async {
    await _hazards.put(hazard.id, jsonEncode(hazard.toMap()));
    return hazard.id;
  }

  Future<List<Hazard>> listHazards() async {
    final out = <Hazard>[];
    for (final v in _hazards.values) {
      try {
        out.add(Hazard.fromMap(jsonDecode(v) as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupt entries.
      }
    }
    out.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return out;
  }

  Future<void> deleteHazard(String id) => _hazards.delete(id);

  /// Build a fresh `Hazard` with a generated id, ready to `addHazard`.
  Hazard newHazard({
    required HazardType type,
    required LatLng position,
    String? note,
    String? edgeId,
  }) {
    return Hazard(
      id: _uuid.v4(),
      type: type,
      position: position,
      note: note,
      edgeId: edgeId,
      reportedAt: DateTime.now(),
    );
  }
}
