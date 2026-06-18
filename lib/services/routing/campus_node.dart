import 'package:latlong2/latlong.dart';

enum NodeType {
  entrance,
  junction,
  landmark,
  building,
  shelter,
}

class CampusNode {
  final String id;
  final LatLng position;
  final String label;
  final NodeType type;

  const CampusNode({
    required this.id,
    required this.position,
    required this.label,
    this.type = NodeType.junction,
  });

  factory CampusNode.fromMap(Map<String, dynamic> map) {
    return CampusNode(
      id: map['id'] as String,
      position: LatLng(
        (map['lat'] as num).toDouble(),
        (map['lng'] as num).toDouble(),
      ),
      label: map['label'] as String,
      type: NodeType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'junction'),
        orElse: () => NodeType.junction,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'lat': position.latitude,
        'lng': position.longitude,
        'label': label,
        'type': type.name,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CampusNode && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
