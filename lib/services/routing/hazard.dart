import 'package:latlong2/latlong.dart';

/// Categories shown on the Community screen, modelled as a closed enum so
/// the routing engine and the community UI can share one source of truth.
enum HazardType {
  construction,
  stairs,
  doors,
  paths,
}

extension HazardTypeX on HazardType {
  String get label => switch (this) {
        HazardType.construction => 'Construction',
        HazardType.stairs => 'Stairs',
        HazardType.doors => 'Doors',
        HazardType.paths => 'Paths',
      };

  static HazardType fromLabel(String label) {
    return HazardType.values.firstWhere(
      (e) => e.label.toLowerCase() == label.toLowerCase(),
      orElse: () => HazardType.paths,
    );
  }
}

/// A community-reported obstacle. `edgeId` is optional: when set, the hazard
/// is bound to a specific graph edge (precise); when null it is a free-form
/// geo point that the store can later snap to the nearest edge.
class Hazard {
  final String id;
  final HazardType type;
  final LatLng position;
  final String? note;
  final DateTime reportedAt;

  /// Optional binding to a CampusEdge id. When present, the routing engine
  /// applies the hazard directly to that edge without spatial matching.
  final String? edgeId;

  const Hazard({
    required this.id,
    required this.type,
    required this.position,
    required this.reportedAt,
    this.note,
    this.edgeId,
  });

  factory Hazard.fromMap(Map<String, dynamic> map) {
    return Hazard(
      id: map['id'] as String,
      type: HazardTypeX.fromLabel(map['type'] as String),
      position: LatLng(
        (map['lat'] as num).toDouble(),
        (map['lng'] as num).toDouble(),
      ),
      note: map['note'] as String?,
      edgeId: map['edge_id'] as String?,
      reportedAt:
          DateTime.fromMillisecondsSinceEpoch(map['reported_at'] as int),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.label,
        'lat': position.latitude,
        'lng': position.longitude,
        'note': note,
        'edge_id': edgeId,
        'reported_at': reportedAt.millisecondsSinceEpoch,
      };
}
