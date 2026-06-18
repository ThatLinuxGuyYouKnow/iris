import 'package:iris/services/routing/campus_edge.dart';
import 'package:iris/services/routing/campus_graph.dart';
import 'package:iris/services/routing/campus_node.dart';
import 'package:latlong2/latlong.dart';

/// A tiny University of Lagos, Akoka stand-in campus so the map renders and
/// routing can be exercised before the real campus dataset is imported.
/// Replace `loadCampusGraph()` with a JSON/GeoJSON loader or a sqflite-backed
/// builder once surveying is done — the engine itself does not care where the
/// graph comes from.
CampusGraph loadCampusGraph() {
  return CampusGraph(nodes: _nodes, edges: _edges);
}

// Coordinates are approximate UNILAG Akoka waypoints; swap for surveyed campus
// waypoints before using this graph for turn-by-turn guidance.
const List<CampusNode> _nodes = [
  CampusNode(
    id: 'gate_a',
    position: LatLng(6.5176, 3.3868),
    label: 'UNILAG Main Gate',
    type: NodeType.entrance,
  ),
  CampusNode(
    id: 'gate_b',
    position: LatLng(6.5152, 3.3943),
    label: 'UNILAG Lagoon Front Gate',
    type: NodeType.entrance,
  ),
  CampusNode(
    id: 'lib',
    position: LatLng(6.5157, 3.3898),
    label: 'University Library',
    type: NodeType.building,
  ),
  CampusNode(
    id: 'sci',
    position: LatLng(6.5166, 3.3913),
    label: 'Faculty of Science',
    type: NodeType.building,
  ),
  CampusNode(
    id: 'arts',
    position: LatLng(6.5171, 3.3894),
    label: 'Faculty of Arts',
    type: NodeType.building,
  ),
  CampusNode(
    id: 'hall',
    position: LatLng(6.5164, 3.3903),
    label: 'UNILAG Senate House',
    type: NodeType.landmark,
  ),
  CampusNode(
    id: 'caf',
    position: LatLng(6.5184, 3.3906),
    label: 'Campus Cafeteria',
    type: NodeType.building,
  ),
  CampusNode(
    id: 'shelter1',
    position: LatLng(6.5160, 3.3893),
    label: 'Library Covered Walkway',
    type: NodeType.shelter,
  ),
];

const List<CampusEdge> _edges = [
  CampusEdge(
    id: 'e_gate_a_lib',
    fromId: 'gate_a',
    toId: 'lib',
    distanceMetres: 120,
    sheltered: false,
  ),
  CampusEdge(
    id: 'e_lib_hall',
    fromId: 'lib',
    toId: 'hall',
    distanceMetres: 70,
    sheltered: false,
  ),
  CampusEdge(
    id: 'e_lib_shelter1',
    fromId: 'lib',
    toId: 'shelter1',
    distanceMetres: 55,
    sheltered: true,
  ),
  CampusEdge(
    id: 'e_shelter1_hall',
    fromId: 'shelter1',
    toId: 'hall',
    distanceMetres: 45,
    sheltered: true,
  ),
  CampusEdge(
    id: 'e_hall_arts',
    fromId: 'hall',
    toId: 'arts',
    distanceMetres: 60,
    hasDoor: true,
  ),
  CampusEdge(
    id: 'e_hall_sci',
    fromId: 'hall',
    toId: 'sci',
    distanceMetres: 80,
    hasStairs: true,
  ),
  CampusEdge(
    id: 'e_sci_gate_b',
    fromId: 'sci',
    toId: 'gate_b',
    distanceMetres: 90,
  ),
  CampusEdge(
    id: 'e_arts_caf',
    fromId: 'arts',
    toId: 'caf',
    distanceMetres: 110,
  ),
  CampusEdge(
    id: 'e_caf_sci',
    fromId: 'caf',
    toId: 'sci',
    distanceMetres: 100,
    hasStairs: false,
  ),
  CampusEdge(
    id: 'e_gate_a_arts',
    fromId: 'gate_a',
    toId: 'arts',
    distanceMetres: 140,
  ),
];
