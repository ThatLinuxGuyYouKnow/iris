import 'package:flutter_test/flutter_test.dart';
import 'package:iris/services/routing/campus_edge.dart';
import 'package:iris/services/routing/campus_graph.dart';
import 'package:iris/services/routing/campus_node.dart';
import 'package:iris/services/routing/hazard.dart';
import 'package:iris/services/routing/routing_engine.dart';
import 'package:latlong2/latlong.dart';

CampusGraph _graph() => CampusGraph(
      nodes: const [
        CampusNode(id: 'a', position: LatLng(0, 0), label: 'A'),
        CampusNode(id: 'b', position: LatLng(0, 0.001), label: 'B'),
        CampusNode(id: 'c', position: LatLng(0, 0.002), label: 'C'),
        CampusNode(id: 'd', position: LatLng(0.001, 0.001), label: 'D'),
      ],
      edges: const [
        // a-b-c is the direct corridor; a-d-c is a longer detour.
        CampusEdge(id: 'ab', fromId: 'a', toId: 'b', distanceMetres: 100),
        CampusEdge(id: 'bc', fromId: 'b', toId: 'c', distanceMetres: 100),
        CampusEdge(id: 'ad', fromId: 'a', toId: 'd', distanceMetres: 150),
        CampusEdge(id: 'dc', fromId: 'd', toId: 'c', distanceMetres: 150),
      ],
    );

void main() {
  test('shortest path with no hazards uses the direct corridor', () {
    final r = RoutingEngine(_graph()).routeBetween('a', 'c');
    expect(r.isEmpty, isFalse);
    expect(r.waypoints.map((n) => n.id), ['a', 'b', 'c']);
    expect(r.distanceMetres, 200);
  });

  test('construction hazard on the short edge forces the detour', () {
    final engine = RoutingEngine(_graph());
    final hazards = [
      Hazard(
        id: 'h1',
        type: HazardType.construction,
        position: const LatLng(0, 0.001),
        edgeId: 'bc',
        reportedAt: DateTime(2026),
      ),
    ];
    final r = engine.routeBetween('a', 'c', activeHazards: hazards);
    expect(r.waypoints.map((n) => n.id), ['a', 'd', 'c']);
    expect(r.distanceMetres, 300);
    // The detour avoids edge `bc`, so the construction hazard on it is
    // NOT on the chosen path — encounteredHazards must be empty.
    expect(r.encounteredHazards, isEmpty);
  });

  test('stairs penalty raises cost but keeps the same path when no alt', () {
    final graph = CampusGraph(
      nodes: const [
        CampusNode(id: 'a', position: LatLng(0, 0), label: 'A'),
        CampusNode(id: 'b', position: LatLng(0, 0.001), label: 'B'),
      ],
      edges: const [
        CampusEdge(
            id: 'ab', fromId: 'a', toId: 'b', distanceMetres: 100, hasStairs: true),
      ],
    );
    final r = RoutingEngine(graph).routeBetween('a', 'b');
    expect(r.waypoints.map((n) => n.id), ['a', 'b']);
    expect(r.cost, greaterThan(100));
  });

  test('unknown endpoints yield an empty result', () {
    final r = RoutingEngine(_graph()).routeBetween('a', 'zzz');
    expect(r.isEmpty, isTrue);
  });

  test('hazard on a traversed edge (no detour) is reported as encountered', () {
    // Only one path a->b exists; a stairs hazard on `ab` can't be avoided,
    // so the route must still traverse it and surface the hazard.
    final graph = CampusGraph(
      nodes: const [
        CampusNode(id: 'a', position: LatLng(0, 0), label: 'A'),
        CampusNode(id: 'b', position: LatLng(0, 0.001), label: 'B'),
      ],
      edges: const [
        CampusEdge(id: 'ab', fromId: 'a', toId: 'b', distanceMetres: 100),
      ],
    );
    final hazard = Hazard(
      id: 'h_stairs',
      type: HazardType.stairs,
      position: const LatLng(0, 0.0005),
      edgeId: 'ab',
      reportedAt: DateTime(2026),
    );
    final r =
        RoutingEngine(graph).routeBetween('a', 'b', activeHazards: [hazard]);
    expect(r.waypoints.map((n) => n.id), ['a', 'b']);
    expect(r.encounteredHazards.single.id, 'h_stairs');
  });

  test('same start and end returns a single-waypoint trivial route', () {
    final r = RoutingEngine(_graph()).routeBetween('a', 'a');
    expect(r.waypoints.single.id, 'a');
    expect(r.distanceMetres, 0);
  });

  test('nearestNode snaps to the closest waypoint', () {
    final g = _graph();
    expect(g.nearestNode(const LatLng(0.0009, 0.0011)).id, 'd');
    expect(g.nearestNode(const LatLng(0, 0.0019)).id, 'c');
  });

  test('routeBetweenPoints snaps endpoints then routes', () {
    final r = RoutingEngine(_graph())
        .routeBetweenPoints(const LatLng(0, 0), const LatLng(0, 0.002));
    expect(r.waypoints.first.id, 'a');
    expect(r.waypoints.last.id, 'c');
  });
}
