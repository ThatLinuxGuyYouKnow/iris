import 'package:iris/services/routing/campus_edge.dart';
import 'package:iris/services/routing/campus_node.dart';
import 'package:latlong2/latlong.dart';

/// Immutable campus graph. Nodes are addressed by id; edges are stored both
/// flat (for serialisation) and as a bidirectional adjacency map (for
/// traversal). Hazards are *not* stored here — they are injected into
/// `RoutingEngine.cost` at query time so community reports can change without
/// rebuilding the graph.
class CampusGraph {
  final Map<String, CampusNode> nodes;
  final Map<String, List<String>> _adjacency;
  final Map<String, CampusEdge> _edgesById;
  final Map<String, List<CampusEdge>> _edgesFrom;

  CampusGraph._({
    required this.nodes,
    required Map<String, List<String>> adjacency,
    required Map<String, CampusEdge> edgesById,
    required Map<String, List<CampusEdge>> edgesFrom,
  })  : _adjacency = adjacency,
        _edgesById = edgesById,
        _edgesFrom = edgesFrom;

  factory CampusGraph({
    required List<CampusNode> nodes,
    required List<CampusEdge> edges,
  }) {
    final nodeMap = {for (final n in nodes) n.id: n};
    final adjacency = <String, List<String>>{};
    final edgesById = <String, CampusEdge>{};
    final edgesFrom = <String, List<CampusEdge>>{};

    for (final n in nodes) {
      adjacency.putIfAbsent(n.id, () => []);
      edgesFrom.putIfAbsent(n.id, () => []);
    }
    for (final e in edges) {
      edgesById[e.id] = e;
      edgesFrom.putIfAbsent(e.fromId, () => []).add(e);
      adjacency.putIfAbsent(e.fromId, () => []).add(e.toId);
      // Treat edges as bidirectional for walking paths.
      edgesFrom.putIfAbsent(e.toId, () => []).add(e);
      adjacency.putIfAbsent(e.toId, () => []).add(e.fromId);
    }
    return CampusGraph._(
      nodes: nodeMap,
      adjacency: adjacency,
      edgesById: edgesById,
      edgesFrom: edgesFrom,
    );
  }

  CampusNode? node(String id) => nodes[id];

  List<CampusEdge> edgesFrom(String nodeId) =>
      _edgesFrom[nodeId] ?? const <CampusEdge>[];

  CampusEdge? edge(String id) => _edgesById[id];

  Iterable<String> neighbours(String nodeId) =>
      _adjacency[nodeId] ?? const <String>[];

  List<CampusNode> get nodeList => nodes.values.toList(growable: false);
  List<CampusEdge> get edgeList => _edgesById.values.toList(growable: false);

  /// Nearest node to `point` by great-circle distance. O(n) — fine for a few
  /// hundred campus waypoints; upgrade to a spatial index if the graph grows.
  CampusNode nearestNode(LatLng point) {
    final d = Distance();
    CampusNode? best;
    double bestDist = double.infinity;
    for (final n in nodes.values) {
      final dist = d.distance(point, n.position);
      if (dist < bestDist) {
        bestDist = dist;
        best = n;
      }
    }
    return best!;
  }

  static double metresBetween(LatLng a, LatLng b) =>
      const Distance().distance(a, b);
}
