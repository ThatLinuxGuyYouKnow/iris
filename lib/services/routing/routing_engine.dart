import 'package:iris/services/routing/campus_edge.dart';
import 'package:iris/services/routing/campus_graph.dart';
import 'package:iris/services/routing/campus_node.dart';
import 'package:iris/services/routing/hazard.dart';
import 'package:latlong2/latlong.dart';

/// Result of a routing query. `waypoints` are the ordered CampusNodes from
/// origin to destination; `polyline` is the same path as lat/lng points ready
/// to feed straight into a `PolylineLayer`; `cost` is the weighted total
/// (not raw metres) and `distanceMetres` is the actual walking distance.
class RouteResult {
  final List<CampusNode> waypoints;
  final List<LatLng> polyline;
  final double cost;
  final double distanceMetres;
  final List<Hazard> encounteredHazards;

  const RouteResult({
    required this.waypoints,
    required this.polyline,
    required this.cost,
    required this.distanceMetres,
    required this.encounteredHazards,
  });

  bool get isEmpty => waypoints.length < 2;

  static RouteResult empty() => const RouteResult(
        waypoints: [],
        polyline: [],
        cost: 0,
        distanceMetres: 0,
        encounteredHazards: [],
      );
}

/// Dijkstra over the campus graph with edge costs that fold in both the
/// edge's static accessibility attributes and any active community hazards.
/// A* is unnecessary here — campus graphs are small and densely connected,
/// so the heuristic adds overhead without meaningful search pruning.
class RoutingEngine {
  final CampusGraph graph;
  final EdgeWeightConfig weights;

  RoutingEngine(this.graph, {this.weights = EdgeWeightConfig.defaultConfig});

  /// Weighted cost of traversing `edge` given the currently active hazards.
  /// Construction hazards on an edge push it toward being avoided (but not
  /// strictly infinite, so a detour-free route still exists if needed).
  double cost(CampusEdge edge, List<Hazard> activeHazards) {
    double base = edge.distanceMetres;
    if (edge.hasStairs) base += weights.stairsPenalty;
    if (edge.hasDoor) base += weights.doorPenalty;
    if (!edge.accessible) base += weights.inaccessiblePenalty;
    if (edge.sheltered) base *= (1 - weights.shelterBonus);

    for (final h in activeHazards) {
      if (h.edgeId != edge.id) continue;
      switch (h.type) {
        case HazardType.construction:
          base *= weights.constructionMultiplier;
          break;
        case HazardType.stairs:
          base += weights.stairsPenalty;
          break;
        case HazardType.doors:
          base += weights.doorPenalty;
          break;
        case HazardType.paths:
          // A 'paths' report generally describes a problematic surface —
          // apply a moderate penalty rather than a hard avoid.
          base *= 3.0;
          break;
      }
    }
    return base;
  }

  /// Compute the lowest-cost path between two node ids.
  RouteResult routeBetween(String startId, String endId,
      {List<Hazard> activeHazards = const []}) {
    if (!graph.nodes.containsKey(startId) ||
        !graph.nodes.containsKey(endId)) {
      return RouteResult.empty();
    }
    if (startId == endId) {
      final n = graph.node(startId)!;
      return RouteResult(
        waypoints: [n],
        polyline: [n.position],
        cost: 0,
        distanceMetres: 0,
        encounteredHazards: const [],
      );
    }

    final dist = <String, double>{startId: 0};
    final prev = <String, String>{};
    final visited = <String>{};
    final frontier = <_HeapEntry>[_HeapEntry(startId, 0)];

    while (frontier.isNotEmpty) {
      frontier.sort((a, b) => a.cost.compareTo(b.cost));
      final current = frontier.removeAt(0).id;
      if (!visited.add(current)) continue;
      if (current == endId) break;

      for (final edge in graph.edgesFrom(current)) {
        final neighbour =
            edge.fromId == current ? edge.toId : edge.fromId;
        if (visited.contains(neighbour)) continue;
        final stepCost = cost(edge, activeHazards);
        final tentative = (dist[current] ?? double.infinity) + stepCost;
        if (tentative < (dist[neighbour] ?? double.infinity)) {
          dist[neighbour] = tentative;
          prev[neighbour] = current;
          frontier.add(_HeapEntry(neighbour, tentative));
        }
      }
    }

    if (!prev.containsKey(endId)) return RouteResult.empty();

    // Reconstruct path.
    final path = <String>[endId];
    String? cur = endId;
    while (cur != null && cur != startId) {
      cur = prev[cur];
      if (cur != null) path.add(cur);
    }
    final ordered = path.reversed.toList();

    final waypoints = ordered.map((id) => graph.node(id)!).toList();
    final polyline = waypoints.map((n) => n.position).toList();

    // Sum real metres and collect hazards hit along the chosen edges.
    double metres = 0;
    final hitHazards = <Hazard>{};
    for (int i = 0; i < ordered.length - 1; i++) {
      final e = _edgeBetween(ordered[i], ordered[i + 1]);
      if (e == null) continue;
      metres += e.distanceMetres;
      for (final h in activeHazards) {
        if (h.edgeId == e.id) hitHazards.add(h);
      }
    }

    return RouteResult(
      waypoints: waypoints,
      polyline: polyline,
      cost: dist[endId]!,
      distanceMetres: metres,
      encounteredHazards: hitHazards.toList(),
    );
  }

  /// Convenience: route between two raw lat/lng points by snapping each to
  /// the nearest graph node first.
  RouteResult routeBetweenPoints(LatLng start, LatLng end,
      {List<Hazard> activeHazards = const []}) {
    return routeBetween(
      graph.nearestNode(start).id,
      graph.nearestNode(end).id,
      activeHazards: activeHazards,
    );
  }

  CampusEdge? _edgeBetween(String a, String b) {
    for (final e in graph.edgesFrom(a)) {
      if (e.toId == b || e.fromId == b) return e;
    }
    return null;
  }
}

class _HeapEntry {
  final String id;
  final double cost;
  const _HeapEntry(this.id, this.cost);
}
