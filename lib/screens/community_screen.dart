import 'package:flutter/material.dart';
import 'package:iris/services/route_store.dart';
import 'package:iris/services/routing/campus_graph.dart';
import 'package:iris/services/routing/hazard.dart';
import 'package:iris/services/routing/sample_campus.dart';
import 'package:iris/themes/theme.dart';
import 'package:iris/widgets/community_guidelines.dart';
import 'package:iris/widgets/community_map_type_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CampusGraph _graph = loadCampusGraph();
  List<Hazard> _hazards = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await RouteStore.instance.init();
    final hazards = await RouteStore.instance.listHazards();
    if (mounted) {
      setState(() {
        _hazards = hazards;
        _loading = false;
      });
    }
  }

  int _countFor(HazardType type) =>
      _hazards.where((h) => h.type == type).length;

  Future<void> _openReport() async {
    final created = await showDialog<Hazard>(
      context: context,
      builder: (ctx) => _ReportHazardDialog(graph: _graph),
    );
    if (created == null) return;
    await RouteStore.instance.addHazard(created);
    await _load();
  }

  Future<void> _openCategory(HazardType type) async {
    final items = _hazards.where((h) => h.type == type).toList();
    await showDialog(
      context: context,
      builder: (ctx) => _CategoryDialog(
        type: type,
        hazards: items,
        onDelete: (id) async {
          await RouteStore.instance.deleteHazard(id);
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Share tricky routes and destinations to help visually-impaired students on campus',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: kTextSecondary),
                ),
                const SizedBox(height: 24),

                // Share action card
                InkWell(
                  onTap: _openReport,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration:
                        kGlassDecoration(opacity: 0.08, borderRadius: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kPrimaryAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: kPrimaryAccent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Share a tricky route',
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Help others by submitting a route that may be hard to navigate',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: kTextSecondary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'Browse by Category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _categoryCard(
                          HazardType.construction, Icons.warning_amber_rounded),
                      const SizedBox(width: 16),
                      _categoryCard(
                          HazardType.stairs, Icons.stairs_outlined),
                      const SizedBox(width: 16),
                      _categoryCard(
                          HazardType.doors, Icons.door_front_door_outlined),
                      const SizedBox(width: 16),
                      _categoryCard(
                          HazardType.paths, Icons.directions_walk),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const CommunityGuidelinesBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryCard(HazardType type, IconData icon) {
    return CommunityMapTypeCard(
      mapType: type.label,
      mapIcon: icon,
      typeCount: _loading ? 0 : _countFor(type),
      onTap: () => _openCategory(type),
    );
  }
}

/// Modal to report a hazard. The hazard is bound to a graph edge (selected by
/// its two endpoints) so the routing engine can apply the cost penalty
/// precisely without spatial snapping. A free-text note is optional.
class _ReportHazardDialog extends StatefulWidget {
  final CampusGraph graph;
  const _ReportHazardDialog({required this.graph});

  @override
  State<_ReportHazardDialog> createState() => _ReportHazardDialogState();
}

class _ReportHazardDialogState extends State<_ReportHazardDialog> {
  HazardType _type = HazardType.construction;
  String? _edgeId;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final edges = widget.graph.edgeList;
    return AlertDialog(
      title: const Text('Share a tricky route'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<HazardType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Hazard type'),
              items: [
                for (final t in HazardType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _edgeId,
              decoration:
                  const InputDecoration(labelText: 'Affected path segment'),
              items: [
                for (final e in edges)
                  DropdownMenuItem(
                    value: e.id,
                    child: Text(
                      '${widget.graph.node(e.fromId)?.label ?? e.fromId} '
                      '↔ ${widget.graph.node(e.toId)?.label ?? e.toId}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _edgeId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. uneven surface, no handrail',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Share'),
        ),
      ],
    );
  }

  void _submit() {
    if (_edgeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a path segment first.')),
      );
      return;
    }
    final edge = widget.graph.edge(_edgeId!)!;
    // Anchor the hazard at the edge's `from` node — the precise location is
    // the segment itself (carried by `edgeId`); this point is just for the
    // map marker.
    final anchor = widget.graph.node(edge.fromId)!.position;
    final hazard = RouteStore.instance.newHazard(
      type: _type,
      position: anchor,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      edgeId: _edgeId,
    );
    Navigator.pop(context, hazard);
  }
}

class _CategoryDialog extends StatelessWidget {
  final HazardType type;
  final List<Hazard> hazards;
  final Future<void> Function(String id) onDelete;

  const _CategoryDialog({
    required this.type,
    required this.hazards,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${type.label} reports'),
      content: SizedBox(
        width: double.maxFinite,
        child: hazards.isEmpty
            ? const Text('No reports yet for this category.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: hazards.length,
                itemBuilder: (_, i) {
                  final h = hazards[i];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(h.note?.isNotEmpty == true
                        ? h.note!
                        : 'No note'),
                    subtitle: Text(
                        '${h.position.latitude.toStringAsFixed(4)}, '
                        '${h.position.longitude.toStringAsFixed(4)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await onDelete(h.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
