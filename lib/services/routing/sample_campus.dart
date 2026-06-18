import 'package:iris/services/routing/campus_edge.dart';
import 'package:iris/services/routing/campus_graph.dart';
import 'package:iris/services/routing/campus_node.dart';
import 'package:latlong2/latlong.dart';

/// A tiny stand-in campus so the map renders and routing can be exercised
/// before the real campus dataset is imported. Replace `loadCampusGraph()`
/// with a JSON/GeoJSON loader or a sqflite-backed builder once surveying
/// is done — the engine itself does not care where the graph comes from.
CampusGraph loadCampusGraph() {
  return CampusGraph(
    nodes: _nodes,
    edges: _edges,
  );
}

// Coordinates are illustrative; swap for surveyed campus waypoints.
const List<CampusNode> _nodes = [
  CampusNode(id: 'gate_a', position: LatLng(6.5240, 3.3790), label: 'Main Gate A', type: NodeType.entrance),
  CampusNode(id: 'gate_b', position: LatLng(6.5255, 3.3812), label: 'East Gate B', type: NodeType.entrance),
  CampusNode(id: 'lib', position: LatLng(6.5248, 3.3799), label: 'University Library', type: NodeType.building),
  CampusNode(id: 'sci', position: LatLng(6.5253, 3.3808), label: 'Science Building', type: NodeType.building),
  CampusNode(id: 'arts', position: LatLng(6.5243, 3.3806), label: 'Arts Building', type: NodeType.building),
  CampusNode(id: 'hall', position: LatLng(6.5249, 3.3803), label: 'Central Plaza', type: NodeType.landmark),
  CampusNode(id: 'caf', position: LatLng(6.5257, 3.3796), label: 'Cafeteria', type: NodeType.building),
  CampusNode(id: 'shelter1', position: LatLng(6.5246, 3.3796), label: 'Covered Walkway', type: NodeType.shelter),
];

const List<CampusEdge> _edges = [
  CampusEdge(id: 'e_gate_a_lib', fromId: 'gate_a', toId: 'lib', distanceMetres: 120, sheltered: false),
  CampusEdge(id: 'e_lib_hall', fromId: 'lib', toId: 'hall', distanceMetres: 70, sheltered: false),
  CampusEdge(id: 'e_lib_shelter1', fromId: 'lib', toId: 'shelter1', distanceMetres: 55, sheltered: true),
  CampusEdge(id: 'e_shelter1_hall', fromId: 'shelter1', toId: 'hall', distanceMetres: 45, sheltered: true),
  CampusEdge(id: 'e_hall_arts', fromId: 'hall', toId: 'arts', distanceMetres: 60, hasDoor: true),
  CampusEdge(id: 'e_hall_sci', fromId: 'hall', toId: 'sci', distanceMetres: 80, hasStairs: true),
  CampusEdge(id: 'e_sci_gate_b', fromId: 'sci', toId: 'gate_b', distanceMetres: 90),
  CampusEdge(id: 'e_arts_caf', fromId: 'arts', toId: 'caf', distanceMetres: 110),
  CampusEdge(id: 'e_caf_sci', fromId: 'caf', toId: 'sci', distanceMetres: 100, hasStairs: false),
  CampusEdge(id: 'e_gate_a_arts', fromId: 'gate_a', toId: 'arts', distanceMetres: 140),
];
