class CampusEdge {
  final String id;
  final String fromId;
  final String toId;

  /// Great-circle metres between endpoints. Computed once at build time.
  final double distanceMetres;

  /// Static attributes of the physical path segment. Community-reported
  /// hazards are applied on top of these at query time so the graph stays
  /// immutable and hazards can be added/removed without rebuilding it.
  final bool hasStairs;
  final bool hasDoor;
  final bool sheltered;
  final bool accessible;

  const CampusEdge({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.distanceMetres,
    this.hasStairs = false,
    this.hasDoor = false,
    this.sheltered = false,
    this.accessible = true,
  });

  Iterable<String> get endpoints sync* {
    yield fromId;
    yield toId;
  }
}

/// Penalties applied on top of raw distance when computing edge cost.
/// Tuned for a visually-impaired walker: stairs and doors are meaningful
/// friction, active construction is treated as a near-block, and sheltered
/// segments get a small bonus (cost reduction) for rainy-day routing.
class EdgeWeightConfig {
  final double stairsPenalty;
  final double doorPenalty;
  final double shelterBonus;
  final double inaccessiblePenalty;
  final double constructionMultiplier;

  const EdgeWeightConfig({
    this.stairsPenalty = 60.0,
    this.doorPenalty = 25.0,
    this.shelterBonus = 0.05,
    this.inaccessiblePenalty = 400.0,
    this.constructionMultiplier = 50.0,
  });

  static const EdgeWeightConfig defaultConfig = EdgeWeightConfig();
}
